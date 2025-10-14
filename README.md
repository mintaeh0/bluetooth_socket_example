### Flutter Bluetooth 통신 및 Socket 예제
재직 중 구현했던 Bluetooth 통신과 Socket 통신 구조를 재구현한 예제 프로젝트입니다.   
통신 과정을 보이기 위해 코드로 구현한 것이며, 실제 데이터는 수신할 수 없는 환경입니다.    
Provider를 이용한 View-Viewmodel 구조의 상태관리를 예로 구현했습니다.   

### 사용 라이브러리
```
provider: ^6.1.5
flutter_blue_classic: ^0.0.6
permission_handler: ^12.0.1
```

### 프로젝트 요약
1. 작업 장비와 Bluetooth로 연결하여 일정 주기로 데이터를 수신합니다.
2. 받은 데이터를 Socket으로 연결된 서버에 전송하면 데이터에 해당하는 보정 정보를 수신할 수 있습니다.
3. 수신한 정보를 다시 Bluetooth로 연결된 장비에 전송하면 장비 고유 연산 시스템에 의해 더 수준 높은 데이터를 수신할 수 있습니다.
4. 위와 같은 과정으로 Bluetooth로 연결된 장비와 Socket 방식으로 연결된 서버는 끊임없이 서로 데이터를 주고 받으며 사용자에게 필요한 데이터를 제공하게 됩니다.

<img width="1311" height="765" alt="image" src="https://github.com/user-attachments/assets/2a2f1792-2bcc-4481-a6d2-b92ddc16acba" />

### ViewModel 요약
`init()`   
크게 3가지의 초기 세팅을 수행합니다.
1. Bluetooth 권한 요청
2. Bluetooth 관련 스트림 구독
3. Socket 관련 설정 및 스트림 구독

`connectToDevice()`   
스캔 목록의 인덱스를 이용하여 블루투스 연결을 수행합니다.   
외부 장치와 연결에 성공하면 지속적으로 데이터를 수신합니다.   
소켓이 연결된 상태라면 수신한 데이터를 소켓 서버로 전송합니다.   

`setSocketSubscription()`   
서버로 소켓 연결을 시도합니다.   
서버와 연결에 성공한 후 블루투스로 수신한 장치 데이터를 전달받으면 지속적으로 관련 데이터를 수신합니다.   
블루투가 연결된 상태라면 수신한 데이터를 장치로 전송합니다.   
