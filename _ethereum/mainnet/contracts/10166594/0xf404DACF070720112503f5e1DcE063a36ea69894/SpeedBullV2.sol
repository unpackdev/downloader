/*
░██████╗██████╗░███████╗███████╗██████╗░██████╗░██╗░░░██╗██╗░░░░░██╗░░░░░  ██████╗░
██╔════╝██╔══██╗██╔════╝██╔════╝██╔══██╗██╔══██╗██║░░░██║██║░░░░░██║░░░░░  ╚════██╗
╚█████╗░██████╔╝█████╗░░█████╗░░██║░░██║██████╦╝██║░░░██║██║░░░░░██║░░░░░  ░░███╔═╝
░╚═══██╗██╔═══╝░██╔══╝░░██╔══╝░░██║░░██║██╔══██╗██║░░░██║██║░░░░░██║░░░░░  ██╔══╝░░
██████╔╝██║░░░░░███████╗███████╗██████╔╝██████╦╝╚██████╔╝███████╗███████╗  ███████╗
╚═════╝░╚═╝░░░░░╚══════╝╚══════╝╚═════╝░╚═════╝░░╚═════╝░╚══════╝╚══════╝  ╚══════╝

Official Telegram: https://t.me/speedbull2

Official Site: https://speedbull2.io

*/

pragma solidity 0.5.11 - 0.6.4;

contract SpeedBullV2 {
     address public ownerWallet;
      uint public currUserID = 0;
      uint public pool1currUserID = 0;
      uint public pool2currUserID = 0;
      uint public pool3currUserID = 0;
      uint public pool4currUserID = 0;
      uint public pool5currUserID = 0;
      uint public pool6currUserID = 0;
      uint public pool7currUserID = 0;
      uint public pool8currUserID = 0;
      uint public pool9currUserID = 0;
      uint public pool10currUserID = 0;
      
      uint public pool1activeUserID = 0;
      uint public pool2activeUserID = 0;
      uint public pool3activeUserID = 0;
      uint public pool4activeUserID = 0;
      uint public pool5activeUserID = 0;
      uint public pool6activeUserID = 0;
      uint public pool7activeUserID = 0;
      uint public pool8activeUserID = 0;
      uint public pool9activeUserID = 0;
      uint public pool10activeUserID = 0;
      
     
      struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
       uint referredUsers;
        mapping(uint => uint) levelExpired;
    }
    
     struct PoolUserStruct {
        bool isExist;
        uint id;
       uint payment_received;
       uint cycle;
    }
    
    mapping (address => UserStruct) public users;
     mapping (uint => address) public userList;
     
     mapping (address => PoolUserStruct) public pool1users;
     mapping (uint => address) public pool1userList;
     
     mapping (address => PoolUserStruct) public pool2users;
     mapping (uint => address) public pool2userList;
     
     mapping (address => PoolUserStruct) public pool3users;
     mapping (uint => address) public pool3userList;
     
     mapping (address => PoolUserStruct) public pool4users;
     mapping (uint => address) public pool4userList;
     
     mapping (address => PoolUserStruct) public pool5users;
     mapping (uint => address) public pool5userList;
     
     mapping (address => PoolUserStruct) public pool6users;
     mapping (uint => address) public pool6userList;
     
     mapping (address => PoolUserStruct) public pool7users;
     mapping (uint => address) public pool7userList;
     
     mapping (address => PoolUserStruct) public pool8users;
     mapping (uint => address) public pool8userList;
     
     mapping (address => PoolUserStruct) public pool9users;
     mapping (uint => address) public pool9userList;
     
     mapping (address => PoolUserStruct) public pool10users;
     mapping (uint => address) public pool10userList;
     
    mapping(uint => uint) public LEVEL_PRICE;
    
   uint REGESTRATION_FESS=0.1 ether;
   uint pool1_price=0.1 ether;
   uint pool2_price=0.2 ether ;
   uint pool3_price=0.5 ether;
   uint pool4_price=1 ether;
   uint pool5_price=2 ether;
   uint pool6_price=5 ether;
   uint pool7_price=10 ether ;
   uint pool8_price=15 ether;
   uint pool9_price=20 ether;
   uint pool10_price=25 ether;
   
   
     event regLevelEvent(address indexed _user, address indexed _referrer, uint _time);
      event getMoneyForLevelEvent(address indexed _user, address indexed _referral, uint indexed _level, uint _time);
      
     event regPoolEntry(address indexed _user, uint indexed _level,   uint _time);
   
     
    event getPoolPayment(address indexed _user,address indexed _receiver, uint indexed _level, uint _time);
   
    UserStruct[] public requests;
     
      constructor(address _player) public {
        ownerWallet = msg.sender;
          
        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: 0,
            referredUsers:0
           
        });
        
       users[ownerWallet] = userStruct;
       userList[currUserID] = ownerWallet;
       
       currUserID++;
       userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: 1,
            referredUsers:0
           
        });
       
       users[_player] = userStruct;
       userList[currUserID] = _player;
       
       
        PoolUserStruct memory pooluserStruct;
        
        pool1currUserID++;

        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool1currUserID,
            payment_received:0,
            cycle: 1
        });
        
       pool1activeUserID=pool1currUserID;
       pool1users[msg.sender] = pooluserStruct;
       pool1userList[pool1currUserID]=msg.sender;
       
       pool1currUserID++;

        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool1currUserID,
            payment_received:0,
            cycle: 1
        });
        
       pool1users[_player] = pooluserStruct;
       pool1userList[pool1currUserID]=_player;
      
        
        pool2currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool2currUserID,
            payment_received:0,
            cycle: 1
        });
    pool2activeUserID=pool2currUserID;
       pool2users[msg.sender] = pooluserStruct;
       pool2userList[pool2currUserID]=msg.sender;
       
       pool2currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool2currUserID,
            payment_received:0,
            cycle: 1
        });
    
       pool2users[_player] = pooluserStruct;
       pool2userList[pool2currUserID]=_player;
       
       
        pool3currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool3currUserID,
            payment_received:0,
            cycle: 1
        });
    pool3activeUserID=pool3currUserID;
       pool3users[msg.sender] = pooluserStruct;
       pool3userList[pool3currUserID]=msg.sender;
       
       pool3currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool3currUserID,
            payment_received:0,
            cycle: 1
        });
    
       pool3users[_player] = pooluserStruct;
       pool3userList[pool3currUserID]=_player;
       
       
         pool4currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool4currUserID,
            payment_received:0,
            cycle: 1
        });
    pool4activeUserID=pool4currUserID;
       pool4users[msg.sender] = pooluserStruct;
       pool4userList[pool4currUserID]=msg.sender;
       
       pool4currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool4currUserID,
            payment_received:0,
            cycle: 1
        });
    
       pool4users[_player] = pooluserStruct;
       pool4userList[pool4currUserID]=_player;

        
          pool5currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool5currUserID,
            payment_received:0,
            cycle: 1
        });
    pool5activeUserID=pool5currUserID;
       pool5users[msg.sender] = pooluserStruct;
       pool5userList[pool5currUserID]=msg.sender;
       
       pool5currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool5currUserID,
            payment_received:0,
            cycle: 1
        });
    
       pool5users[_player] = pooluserStruct;
       pool5userList[pool5currUserID]=_player;
       
       
         pool6currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool6currUserID,
            payment_received:0,
            cycle: 1
        });
    pool6activeUserID=pool6currUserID;
       pool6users[msg.sender] = pooluserStruct;
       pool6userList[pool6currUserID]=msg.sender;
       
       
       pool6currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool6currUserID,
            payment_received:0,
            cycle: 1
        });
   
       pool6users[_player] = pooluserStruct;
       pool6userList[pool6currUserID]=_player;
       
         pool7currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool7currUserID,
            payment_received:0,
            cycle: 1
        });
    pool7activeUserID=pool7currUserID;
       pool7users[msg.sender] = pooluserStruct;
       pool7userList[pool7currUserID]=msg.sender;
       
       pool7currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool7currUserID,
            payment_received:0,
            cycle: 1
        });
    
       pool7users[_player] = pooluserStruct;
       pool7userList[pool7currUserID]=_player;
       
       pool8currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool8currUserID,
            payment_received:0,
            cycle: 1
        });
    pool8activeUserID=pool8currUserID;
       pool8users[msg.sender] = pooluserStruct;
       pool8userList[pool8currUserID]=msg.sender;
       
       pool8currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool8currUserID,
            payment_received:0,
            cycle: 1
        });
   
       pool8users[_player] = pooluserStruct;
       pool8userList[pool8currUserID]=_player;
       
        pool9currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool9currUserID,
            payment_received:0,
            cycle: 1
        });
    pool9activeUserID=pool9currUserID;
       pool9users[msg.sender] = pooluserStruct;
       pool9userList[pool9currUserID]=msg.sender;
       
       pool9currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool9currUserID,
            payment_received:0,
            cycle: 1
        });
    
       pool9users[_player] = pooluserStruct;
       pool9userList[pool9currUserID]=_player;
       
       
        pool10currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool10currUserID,
            payment_received:0,
            cycle: 1
        });
    pool10activeUserID=pool10currUserID;
       pool10users[msg.sender] = pooluserStruct;
       pool10userList[pool10currUserID]=msg.sender;
       
       pool10currUserID++;
        pooluserStruct = PoolUserStruct({
            isExist:true,
            id:pool10currUserID,
            payment_received:0,
            cycle: 1
        });
   
       pool10users[_player] = pooluserStruct;
       pool10userList[pool10currUserID]=_player;
       
       
      }
     
     function regUser(uint _referrerID) public payable {
       
      require(!users[msg.sender].isExist, "User Exists");
      require(_referrerID > 0 && _referrerID <= currUserID, 'Incorrect referral ID');
      require(msg.value == REGESTRATION_FESS, 'Incorrect Value');
       
        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: _referrerID,
            referredUsers:0
        });
   
    
       users[msg.sender] = userStruct;
       userList[currUserID]=msg.sender;
       
        users[userList[users[msg.sender].referrerID]].referredUsers=users[userList[users[msg.sender].referrerID]].referredUsers+1;
        
       payReferral(1,msg.sender);
        emit regLevelEvent(msg.sender, userList[_referrerID], now);
    }
   
   
     function payReferral(uint _level, address _user) internal {
        address referer;
       
        referer = userList[users[_user].referrerID];
       
       
         bool sent = false;
       
            uint level_price_local=0;
            
            level_price_local=REGESTRATION_FESS/10;
            
            sent = address(uint160(referer)).send(level_price_local);

            if (sent) {
                emit getMoneyForLevelEvent(referer, msg.sender, _level, now);
                    if(_level < 10 && users[referer].referrerID >= 1){
                        payReferral(_level+1,referer);
                    }
                    else {
                        sendBalance();
                    }
            }
       
        if(!sent) {

            payReferral(_level, referer);
        }
     }
   
   
       function buyPool1() public payable {
       require(users[msg.sender].isExist, "User Not Registered");
       require(!pool1users[msg.sender].isExist, "Already in AutoPool");
       require(msg.value == pool1_price, 'Incorrect Value');
        
       
        PoolUserStruct memory userStruct;
        address pool1Currentuser=pool1userList[pool1activeUserID];
        
        if(pool1users[pool1Currentuser].payment_received >= 2) {
           reinvestPool1(pool1Currentuser);
           pool1activeUserID+=1;
           pool1Currentuser=pool1userList[pool1activeUserID];
           
       }
        pool1currUserID++;

        userStruct = PoolUserStruct({
            isExist:true,
            id:pool1currUserID,
            payment_received:0,
            cycle: 1
        });
   
       pool1users[msg.sender] = userStruct;
       pool1userList[pool1currUserID]=msg.sender;
       
       bool sent = false;
       
           sent = address(uint160(pool1Currentuser)).send(pool1_price);

            if (sent) {
                pool1users[pool1Currentuser].payment_received+=1;
                
                emit getPoolPayment(msg.sender,pool1Currentuser, 1, now);
            }
            emit regPoolEntry(msg.sender, 1, now);
    }
    
        function reinvestPool1(address _pool1CurrentUser) private  {
        
            PoolUserStruct memory userStruct;
            
            pool1currUserID++;
    
            userStruct = PoolUserStruct({
                isExist:true,
                id:pool1currUserID,
                payment_received:0,
                cycle: pool1users[_pool1CurrentUser].cycle+1
            });
       
          pool1users[_pool1CurrentUser] = userStruct;
          pool1userList[pool1currUserID]=_pool1CurrentUser;
          
          emit regPoolEntry(_pool1CurrentUser, 1, now);
    }
    
    
      function buyPool2() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(msg.value == pool2_price, 'Incorrect Value');
        require(!pool2users[msg.sender].isExist, "Already in AutoPool");
         
        PoolUserStruct memory userStruct;
        address pool2Currentuser=pool2userList[pool2activeUserID];
        
        if(pool2users[pool2Currentuser].payment_received >= 2) {
           reinvestPool2(pool2Currentuser);
           pool2activeUserID+=1;
           pool2Currentuser=pool2userList[pool2activeUserID];
       }
        
        pool2currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool2currUserID,
            payment_received:0,
            cycle: 1
        });
      pool2users[msg.sender] = userStruct;
      pool2userList[pool2currUserID]=msg.sender;
      
      bool sent = false;
      sent = address(uint160(pool2Currentuser)).send(pool2_price);

            if (sent) {
                pool2users[pool2Currentuser].payment_received+=1;
                
                emit getPoolPayment(msg.sender,pool2Currentuser, 2, now);
            }
            emit regPoolEntry(msg.sender,2,  now);
    }
    
    function reinvestPool2(address _pool2CurrentUser) private  {
        
            PoolUserStruct memory userStruct;
            
            pool2currUserID++;
    
            userStruct = PoolUserStruct({
                isExist:true,
                id:pool2currUserID,
                payment_received:0,
                cycle: pool2users[_pool2CurrentUser].cycle+1
            });
       
          pool2users[_pool2CurrentUser] = userStruct;
          pool2userList[pool2currUserID]=_pool2CurrentUser;
          
          emit regPoolEntry(_pool2CurrentUser, 2, now);
    }
    
    
     function buyPool3() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(msg.value == pool3_price, 'Incorrect Value');
        require(!pool3users[msg.sender].isExist, "Already in AutoPool");
        
        
        PoolUserStruct memory userStruct;
        address pool3Currentuser=pool3userList[pool3activeUserID];
        
        if(pool3users[pool3Currentuser].payment_received >= 2) {
           reinvestPool3(pool3Currentuser);
           pool3activeUserID+=1;
           pool3Currentuser=pool3userList[pool3activeUserID];
       }
        
        pool3currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool3currUserID,
            payment_received:0,
            cycle: 1
        });
      pool3users[msg.sender] = userStruct;
      pool3userList[pool3currUserID]=msg.sender;
      
      bool sent = false;
      sent = address(uint160(pool3Currentuser)).send(pool3_price);

            if (sent) {
                pool3users[pool3Currentuser].payment_received+=1;
                
                emit getPoolPayment(msg.sender,pool3Currentuser, 3, now);
            }
        emit regPoolEntry(msg.sender,3,  now);
    }
    
    function reinvestPool3(address _pool3CurrentUser) private  {
        
            PoolUserStruct memory userStruct;
            
            pool3currUserID++;
    
            userStruct = PoolUserStruct({
                isExist:true,
                id:pool3currUserID,
                payment_received:0,
                cycle: pool3users[_pool3CurrentUser].cycle+1
            });
       
          pool3users[_pool3CurrentUser] = userStruct;
          pool3userList[pool3currUserID]=_pool3CurrentUser;
          
          emit regPoolEntry(_pool3CurrentUser, 3, now);
    }
    
    
    function buyPool4() public payable {
      require(users[msg.sender].isExist, "User Not Registered");
      require(msg.value == pool4_price, 'Incorrect Value');
      require(!pool4users[msg.sender].isExist, "Already in AutoPool");
      
        PoolUserStruct memory userStruct;
        address pool4Currentuser=pool4userList[pool4activeUserID];
        
        if(pool4users[pool4Currentuser].payment_received >= 2) {
           reinvestPool4(pool4Currentuser);
           pool4activeUserID+=1;
           pool4Currentuser=pool4userList[pool4activeUserID];
       }
        
        pool4currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool4currUserID,
            payment_received:0,
            cycle: 1
        });
        
      pool4users[msg.sender] = userStruct;
      pool4userList[pool4currUserID]=msg.sender;
      
      bool sent = false;
      sent = address(uint160(pool4Currentuser)).send(pool4_price);

            if (sent) {
                pool4users[pool4Currentuser].payment_received+=1;
                
                 emit getPoolPayment(msg.sender,pool4Currentuser, 4, now);
            }
        emit regPoolEntry(msg.sender,4, now);
    }
    
    function reinvestPool4(address _pool4CurrentUser) private  {
        
            PoolUserStruct memory userStruct;
            
            pool4currUserID++;
    
            userStruct = PoolUserStruct({
                isExist:true,
                id:pool4currUserID,
                payment_received:0,
                cycle: pool4users[_pool4CurrentUser].cycle+1
            });
       
          pool4users[_pool4CurrentUser] = userStruct;
          pool4userList[pool4currUserID]=_pool4CurrentUser;
          
          emit regPoolEntry(_pool4CurrentUser, 4, now);
    }
    
    
    
    function buyPool5() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(msg.value == pool5_price, 'Incorrect Value');
        require(!pool5users[msg.sender].isExist, "Already in AutoPool");
        
        PoolUserStruct memory userStruct;
        address pool5Currentuser=pool5userList[pool5activeUserID];
        
        if(pool5users[pool5Currentuser].payment_received >= 2) {
           reinvestPool5(pool5Currentuser);
           pool5activeUserID+=1;
           pool5Currentuser=pool5userList[pool5activeUserID];
       }
        
        pool5currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool5currUserID,
            payment_received:0,
            cycle: 1
        });
        
      pool5users[msg.sender] = userStruct;
      pool5userList[pool5currUserID]=msg.sender;
      
      bool sent = false;
      sent = address(uint160(pool5Currentuser)).send(pool5_price);

            if (sent) {
                pool5users[pool5Currentuser].payment_received+=1;
                
                 emit getPoolPayment(msg.sender,pool5Currentuser, 5, now);
            }
        emit regPoolEntry(msg.sender,5,  now);
    }
    
    function reinvestPool5(address _pool5CurrentUser) private  {
        
            PoolUserStruct memory userStruct;
            
            pool5currUserID++;
    
            userStruct = PoolUserStruct({
                isExist:true,
                id:pool5currUserID,
                payment_received:0,
                cycle: pool5users[_pool5CurrentUser].cycle+1
            });
       
          pool5users[_pool5CurrentUser] = userStruct;
          pool5userList[pool5currUserID]=_pool5CurrentUser;
          
          emit regPoolEntry(_pool5CurrentUser, 5, now);
    }
    
    function buyPool6() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(msg.value == pool6_price, 'Incorrect Value');
        require(!pool6users[msg.sender].isExist, "Already in AutoPool");
        
        PoolUserStruct memory userStruct;
        address pool6Currentuser=pool6userList[pool6activeUserID];
        
        if(pool6users[pool6Currentuser].payment_received >= 2) {
           reinvestPool6(pool6Currentuser);
           pool6activeUserID+=1;
           pool6Currentuser=pool6userList[pool6activeUserID];
       }
        
        pool6currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool6currUserID,
            payment_received:0,
            cycle: 1
        });
      pool6users[msg.sender] = userStruct;
      pool6userList[pool6currUserID]=msg.sender;
      bool sent = false;
      sent = address(uint160(pool6Currentuser)).send(pool6_price);

            if (sent) {
                pool6users[pool6Currentuser].payment_received+=1;
                
                 emit getPoolPayment(msg.sender,pool6Currentuser, 6, now);
            }
        emit regPoolEntry(msg.sender,6,  now);
    }
    
    function reinvestPool6(address _pool6CurrentUser) private  {
        
            PoolUserStruct memory userStruct;
            
            pool6currUserID++;
    
            userStruct = PoolUserStruct({
                isExist:true,
                id:pool6currUserID,
                payment_received:0,
                cycle: pool6users[_pool6CurrentUser].cycle+1
            });
       
          pool6users[_pool6CurrentUser] = userStruct;
          pool6userList[pool6currUserID]=_pool6CurrentUser;
          
          emit regPoolEntry(_pool6CurrentUser, 6, now);
    }
    
    function buyPool7() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(msg.value == pool7_price, 'Incorrect Value');
        require(!pool7users[msg.sender].isExist, "Already in AutoPool");
        
        PoolUserStruct memory userStruct;
        address pool7Currentuser=pool7userList[pool7activeUserID];
        
        if(pool7users[pool7Currentuser].payment_received >= 2) {
           reinvestPool7(pool7Currentuser);
           pool7activeUserID+=1;
           pool7Currentuser=pool7userList[pool7activeUserID];
       }
        
        pool7currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool7currUserID,
            payment_received:0,
            cycle: 1
        });
      pool7users[msg.sender] = userStruct;
      pool7userList[pool7currUserID]=msg.sender;
      bool sent = false;
      sent = address(uint160(pool7Currentuser)).send(pool7_price);

            if (sent) {
                pool7users[pool7Currentuser].payment_received+=1;
                
                 emit getPoolPayment(msg.sender,pool7Currentuser, 7, now);
            }
        emit regPoolEntry(msg.sender,7,  now);
    }
    
    function reinvestPool7(address _pool7CurrentUser) private  {
        
            PoolUserStruct memory userStruct;
            
            pool7currUserID++;
    
            userStruct = PoolUserStruct({
                isExist:true,
                id:pool7currUserID,
                payment_received:0,
                cycle: pool7users[_pool7CurrentUser].cycle+1
            });
       
          pool7users[_pool7CurrentUser] = userStruct;
          pool7userList[pool7currUserID]=_pool7CurrentUser;
          
          emit regPoolEntry(_pool7CurrentUser, 7, now);
    }
    
    
    function buyPool8() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(msg.value == pool8_price, 'Incorrect Value');
        require(!pool8users[msg.sender].isExist, "Already in AutoPool");
       
        PoolUserStruct memory userStruct;
        address pool8Currentuser=pool8userList[pool8activeUserID];
        
        if(pool8users[pool8Currentuser].payment_received >= 2) {
           reinvestPool8(pool8Currentuser);
           pool8activeUserID+=1;
           pool8Currentuser=pool8userList[pool8activeUserID];
       }
        
        pool8currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool8currUserID,
            payment_received:0,
            cycle:1
        });
      pool8users[msg.sender] = userStruct;
      pool8userList[pool8currUserID]=msg.sender;
      bool sent = false;
      sent = address(uint160(pool8Currentuser)).send(pool8_price);

            if (sent) {
                pool8users[pool8Currentuser].payment_received+=1;
                
                 emit getPoolPayment(msg.sender,pool8Currentuser, 8, now);
            }
        emit regPoolEntry(msg.sender,8,  now);
    }
    
    function reinvestPool8(address _pool8CurrentUser) private  {
        
            PoolUserStruct memory userStruct;
            
            pool8currUserID++;
    
            userStruct = PoolUserStruct({
                isExist:true,
                id:pool8currUserID,
                payment_received:0,
                cycle: pool8users[_pool8CurrentUser].cycle+1
            });
       
          pool8users[_pool8CurrentUser] = userStruct;
          pool8userList[pool8currUserID]=_pool8CurrentUser;
          
          emit regPoolEntry(_pool8CurrentUser, 8, now);
    }
    
    
    
    function buyPool9() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(msg.value == pool9_price, 'Incorrect Value');
        require(!pool9users[msg.sender].isExist, "Already in AutoPool");
       
        PoolUserStruct memory userStruct;
        address pool9Currentuser=pool9userList[pool9activeUserID];
        
        if(pool9users[pool9Currentuser].payment_received >= 2) {
           reinvestPool9(pool9Currentuser);
           pool9activeUserID+=1;
           pool9Currentuser=pool9userList[pool9activeUserID];
       }
        
        pool9currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool9currUserID,
            payment_received:0,
            cycle: 1
        });
      pool9users[msg.sender] = userStruct;
      pool9userList[pool9currUserID]=msg.sender;
      bool sent = false;
      sent = address(uint160(pool9Currentuser)).send(pool9_price);

            if (sent) {
                pool9users[pool9Currentuser].payment_received+=1;
                
                 emit getPoolPayment(msg.sender,pool9Currentuser, 9, now);
            }
        emit regPoolEntry(msg.sender,9,  now);
    }
    
    function reinvestPool9(address _pool9CurrentUser) private  {
        
            PoolUserStruct memory userStruct;
            
            pool9currUserID++;
    
            userStruct = PoolUserStruct({
                isExist:true,
                id:pool9currUserID,
                payment_received:0,
                cycle: pool9users[_pool9CurrentUser].cycle+1
            });
       
          pool9users[_pool9CurrentUser] = userStruct;
          pool9userList[pool9currUserID]=_pool9CurrentUser;
          
          emit regPoolEntry(_pool9CurrentUser, 9, now);
    }
    
    
    function buyPool10() public payable {
        require(users[msg.sender].isExist, "User Not Registered");
        require(msg.value == pool10_price, 'Incorrect Value');
        require(!pool10users[msg.sender].isExist, "Already in AutoPool");
        
        PoolUserStruct memory userStruct;
        address pool10Currentuser=pool10userList[pool10activeUserID];
        
        if(pool10users[pool10Currentuser].payment_received >= 2) {
           reinvestPool10(pool10Currentuser);
           pool10activeUserID+=1;
           pool10Currentuser=pool10userList[pool10activeUserID];
       }
        
        pool10currUserID++;
        userStruct = PoolUserStruct({
            isExist:true,
            id:pool10currUserID,
            payment_received:0,
            cycle: 1
        });
        
      pool10users[msg.sender] = userStruct;
      pool10userList[pool10currUserID]=msg.sender;
      
      bool sent = false;
      sent = address(uint160(pool10Currentuser)).send(pool10_price);

            if (sent) {
                pool10users[pool10Currentuser].payment_received+=1;
                
                 emit getPoolPayment(msg.sender,pool10Currentuser, 10, now);
            }
        emit regPoolEntry(msg.sender, 10, now);
    }
    
    function reinvestPool10(address _pool10CurrentUser) private  {
        
            PoolUserStruct memory userStruct;
            
            pool10currUserID++;
    
            userStruct = PoolUserStruct({
                isExist:true,
                id:pool10currUserID,
                payment_received:0,
                cycle: pool10users[_pool10CurrentUser].cycle+1
            });
       
          pool10users[_pool10CurrentUser] = userStruct;
          pool10userList[pool10currUserID]=_pool10CurrentUser;
          
          emit regPoolEntry(_pool10CurrentUser, 10, now);
    }
    
    function getEthBalance() public view returns(uint) {
    return address(this).balance;
    }
    
    function sendBalance() private
    {
        if(getEthBalance() > 0){
             if (!address(uint160(ownerWallet)).send(getEthBalance()))
             {
                 
             }
        }
    }
   
   
}