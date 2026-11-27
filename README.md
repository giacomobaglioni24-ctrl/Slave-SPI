\# Guida alla programmazione e al collegamento – VirtLAB



L'archivio `fpga-user.zip` contiene tutti i file sorgente necessari per sintetizzare e far funzionare correttamente la top-level entity `fpga-user.vhd`.



\---



\## 1. Procedura di programmazione VirtLAB



\### Programmazione dei Microcontrollori (MCU)

1\. \*\*Collegamento e selezione target:\*\* Collega la scheda al PC tramite il connettore \*\*Micro USB\*\*. Utilizzando `StLinkBridge` da terminale oppure l'interfaccia grafica Java \*\*VirtLabUI\*\*, seleziona il microcontrollore da programmare:

&#x20;  \* \*\*Master MCU\*\* (indicato dal \*\*LED Arancione\*\*)

&#x20;  \* \*\*User MCU\*\* (indicato dal \*\*LED Verde\*\*)

2\. \*\*Caricamento del firmware:\*\* Apri \*\*STM32CubeProgrammer\*\* ed esegui in sequenza:

&#x20;  \* \*\*Open file\*\* per selezionare il file del firmware.

&#x20;  \* \*\*Connect\*\* per stabilire la connessione con il microcontrollore selezionato.

&#x20;  \* \*\*Download\*\* per scrivere il firmware.

3\. \*\*Avvio del firmware:\*\* Alla comparsa del pop-up di completamento, spegni e riaccendi la scheda per mandare in esecuzione il codice.



> \*\*Nota:\*\* I firmware dei microcontrollori vengono salvati nella memoria \*\*FLASH\*\* e rimangono memorizzati anche dopo lo spegnimento della scheda.



\### Programmazione della FPGA

1\. \*\*Generazione del bitstream:\*\* Compila il progetto in \*\*Quartus\*\* e genera il file binario \*\*`.rbf`\*\* (\*Raw Binary File\*).

2\. \*\*Caricamento su FPGA:\*\* Tramite \*\*VirtLabUI\*\*, programma la \*\*User FPGA\*\* selezionando il file `.rbf` appena ottenuto.



> \*\*Attenzione:\*\* La memoria di configurazione della FPGA è volatile; il bitstream viene perso ad ogni spegnimento o riavvio della scheda e deve essere ricaricato tramite VirtLabUI.



\---



\## 2. Collegamento Seriale



Per stabilire la comunicazione seriale dal PC (utilizzando terminali come \*\*Hercules\*\*, \*\*PuTTY\*\*, ecc.):



\* \*\*Connessione fisica:\*\* Collega un cavo \*\*USB Type-C\*\* alla porta \*\*USER USB\*\*, posizionata sulla scheda tra i connettori \*\*`J603`\*\* e \*\*`J601`\*\*.

\* \*\*Selezione della porta:\*\* Apri \*\*Gestione Dispositivi\*\* di Windows per verificare il numero della porta \*\*`COM`\*\* assegnata alla scheda.

\* \*\*Configurazione:\*\* Imposta il \*\*Baud Rate\*\* a \*\*`9600`\*\*.

