import React, { useState, useRef } from 'react';
import { ResponsiveContainer, LineChart, Line } from 'recharts';
import { IonButton, IonItem, IonContent, IonHeader, IonPage, IonTitle, IonToolbar, IonList, IonLabel } from '@ionic/react';
import { mean, number, std } from 'mathjs';
import './Tab1.css';

const { FibriCheckCordovaSDK: fc } = cordova.plugins;


const timeDiffArr = [];
let latestTS = 0;

function logTime(){

  const currTS = Date.now();

  if(latestTS != 0){
      const diffTS = currTS - latestTS
      timeDiffArr.push(diffTS);
  }

  latestTS = currTS;
}

const Tab1: React.FC = () => {

  let [log, setLog] = useState<JSX.Element[]>([]);

  let [receivedEvents, setEvents] = useState({
    onSampleReady: false,
    onFingerDetected: false,
    onFingerRemoved: false,
    onCalibrationReady: false,
    onHeartBeat: false, 
    onTimeRemaining: false,
    onMeasurementFinished: false,
    onMeasurementStart: false,
    onFingerDetectionTimeExpired: false,
    onPulseDetected: false,
    onPulseDetectionTimeExpired: false,
    onMovementDetected: false,
    onMeasurementProcessed: false,
    onMeasurementError: false
  });

  const receivedEventsRef = useRef<Object>();
  receivedEventsRef.current = receivedEvents;


  const [dataPoints, setDataPoints] = useState<Object[]>([]);
  const [heartRate, setHeartRate] = useState<number>(0);
  const [samples, setSamples] = useState(0);
  const [meanSampleRate, setMeanSampleRate] = useState(0);
  const [seconds, setSeconds] = useState(0);

  const [maxPPG, setMax] = useState(0);
  const [minPPG, setMin] = useState(0);
  const [lastPPG, setLast] = useState(0);


  const addLogLine = (logLine: String) => {
    log.push((<IonItem><IonLabel>{new Date().toLocaleTimeString()} - {logLine}</IonLabel></IonItem>));
    setLog(log);
  }

  const addDataPoint = (point: number, raw: number) => {
    setDataPoints(prev => {

      let newArr = [...prev, {name: `${Date.now()}`, ppg: point, raw: raw}]

      return newArr.slice(Math.max(newArr.length - 90,0));
    })
  }

  
  const updateEventsStatus = (eventName: string) => {

    const newEvent = {}
    newEvent[eventName] = true;

    setEvents((prevState) => {
      return {
        ...prevState,
        ...newEvent
      }
    });
  }
  const startMeasurement = async () => {
    await fc.initialise();

    await fc.updateConfiguration({
      flashEnabled: true,
      sampleTime: 30
    })

    fc.onMeasurementStart(() => {
      updateEventsStatus("onMeasurementStart");
      addLogLine("onMeasurementStart")
    });

    fc.onMeasurementFinished(() => {
      updateEventsStatus("onMeasurementFinished");
      addLogLine("onMeasurementFinished")

    });

    fc.onMeasurementProcessed((data) => {
      updateEventsStatus("onMeasurementProcessed");
      addLogLine("onMeasurementProcessed")


      fc.stopMeasurement();
    });


    fc.onSampleReady((ppg:number, raw:number) => {
      if(!receivedEventsRef.current["onSampleReady"]){
        addLogLine("onSampleReady")
      }
      updateEventsStatus("onSampleReady");
      addDataPoint(ppg, raw);
      setMax(prev => Math.max(prev,ppg));
      setMin(prev => Math.min(prev, ppg));
      setLast(ppg);

      logTime();
    })

    fc.onHeartBeat((hr: number) => {
      updateEventsStatus("onHeartBeat");
      addLogLine(`onHeartBeat ${hr}`)
      setHeartRate(hr);
    })

    fc.onTimeRemaining((sec: number) => {
      updateEventsStatus("onTimeRemaining");
      addLogLine(`onTimeRemaining ${sec}`)

      setSeconds(sec);
    })

    fc.onTimeRemaining((sec: number) => {
      updateEventsStatus("onTimeRemaining");
      addLogLine("onTimeRemaining")

      setSeconds(sec);
    })

    fc.onFingerDetected(() => {
      updateEventsStatus("onFingerDetected");
      addLogLine("onFingerDetected")

    })

    fc.onFingerRemoved(() => {
      updateEventsStatus("onFingerRemoved");
      addLogLine("onFingerRemoved")

    })

    fc.onCalibrationReady(() => {
      updateEventsStatus("onCalibrationReady");
      addLogLine("onCalibrationReady")

    })

    fc.onPulseDetected(() => {
      updateEventsStatus("onPulseDetected");
      addLogLine("onPulseDetected")

    })

    fc.onPulseDetectionTimeExpired(() => {
      updateEventsStatus("onPulseDetectionTimeExpired");
      addLogLine("onPulseDetectionTimeExpired")

    })

    fc.onMovementDetected(() => {
      updateEventsStatus("onMovementDetected");
      addLogLine("onMovementDetected")
    })

    setInterval(() => {

      if(timeDiffArr.length > 0){
        setSamples(timeDiffArr.length);
        setMeanSampleRate(1000/mean(timeDiffArr));
      }
    
    }, 1000);

    await fc.startMeasurement();
  }

  return (
    <IonPage>
      <IonHeader>
        <IonToolbar>
          <IonTitle>FibriCheck</IonTitle>
        </IonToolbar>
      </IonHeader>
      <IonContent fullscreen>
        <IonHeader collapse="condense">
          <IonToolbar>
            <IonTitle size="large">FibriCheck Demo</IonTitle>
          </IonToolbar>
        </IonHeader>
        <IonButton expand="block" onClick={startMeasurement}>Start Measurement</IonButton>
        <IonItem>
          Heartrate: {heartRate}
        </IonItem>
        <IonItem>
          Seconds remaining: {seconds}
        </IonItem>
        <IonItem>
          Samples: {samples} | FPS: {meanSampleRate} | Curr: {lastPPG} | High: {maxPPG} | Min: {minPPG}
        </IonItem>
        <IonItem>
            <LineChart width={300} height={200} data={dataPoints}>
              <Line type="monotone" dataKey="ppg" stroke="#ff0000" strokeWidth={2} />
            </LineChart>
        </IonItem>
        <IonItem>
            <LineChart width={300} height={100} data={dataPoints}>
              <Line type="monotone" dataKey="raw" stroke="#ff0000" strokeWidth={2} />
            </LineChart>
        </IonItem>
        <IonItem>
          <table>
            {(() => {
              const items = [];

              for(const [key, value] of Object.entries(receivedEvents)){

                items.push(<tr>
                  <td>{key}</td>
                  <td>{value ? "✅": "❌"}</td>
                </tr>)
              }

              return items;

            })()}
          </table>
        </IonItem>
        <IonItem>
          <IonList>
            {log}
          </IonList>
        </IonItem>
      </IonContent>
    </IonPage>
  );
};

export default Tab1;
