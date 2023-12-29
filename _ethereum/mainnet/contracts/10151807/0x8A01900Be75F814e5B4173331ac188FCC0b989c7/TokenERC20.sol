pragma solidity 0.4.26;


/**
 * @title SafeMath
 * @dev  Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
      c = a + b;
      assert(c >= a);
      return c;
    }


    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }



  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }



  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert( b > 0 );   // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b);   // There is no case in which this doesn't hold
    return a / b;
  }




  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
      require( b != 0 );
      return a % b;
  }

}








contract PublicFun{

   function isContract(address addr) view internal returns (bool) {
          uint size;
          assembly { size := extcodesize(addr) }
                   if( size > 0 ){
                      return true;
                   }
                   if( size == 0  ){
                      return false;
                   }
      }




  function w(uint val) pure internal  returns (uint) {   return val * 1000000000000000000 ;  }

  function t(uint val) pure internal returns (uint) { return val * 1 ether;  }

  function f(uint val) pure internal returns (uint) { return val * 1 finney;  }

  function sz(uint val) pure internal returns (uint) { return val * 1 szabo;  }

  function s(uint val) pure internal returns (uint) { return val * 1 seconds; }

  function m(uint val) pure internal returns (uint)  { return val * 1 minutes; }

  function h(uint val) pure internal returns (uint) { return val * 1 hours; }

  function d(uint val) pure internal returns (uint) {  return val * 1 days;  }


}







contract Ownable is PublicFun {

  address public owner;
  address public COO;
  address public CTO;


  mapping (address => uint ) internal AdminAddr;


  mapping (address => uint ) internal AuthAddr;


  mapping (uint => address[] ) internal RecordingAddr;


  uint[8] public Switch0 = [0,0,1,1,1,1,0,1];



  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender account.
   *
   */
  constructor() public {
    owner = msg.sender;
    COO = msg.sender;
    CTO = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
      modifier onlyOwner() {
        require(msg.sender == owner);
        _;
      }


      modifier onlyCOO() {
        require( Switch0[0] == 0 && msg.sender == COO );
        _;
      }


      modifier onlyCTO() {
        require( Switch0[1] == 0 && msg.sender == CTO );
        _;
      }



      modifier onlyAuthAddr() {
        require( Switch0[2] == 0 );

         if( isContract( msg.sender ) == false ){
                require( msg.sender == CTO );
          }else{
                require( isContract( msg.sender ) == true );
                require( AuthAddr[msg.sender] == 1 );
          }

          _;
      }



      modifier onlyAdminAddr() {

        require( Switch0[3] == 0 );

        if( isContract( msg.sender ) == false ){
           require( msg.sender == CTO );
        }else{
           require( isContract( msg.sender ) == true );
           require( AdminAddr[msg.sender] == 1 );
        }
        _;
      }




    function SetAdminAddr(address Addr,uint val) public onlyCTO returns (bool) {
       require( Switch0[4] == 0 && val >= 0 && val <= 1 );
         if( AdminAddr[Addr] != val ){
              AdminAddr[Addr] = val;
              if( val == 1 ){
                RecordingAddr[1].push( Addr );
              }
          }
       return true;
    }




  function SetAuthAddr(address Addr,uint val) public onlyAdminAddr returns (bool) {
      require( Switch0[5] == 0 && val >= 0 && val <= 1);

       if( AuthAddr[Addr] != val ){
           AuthAddr[Addr] = val ;
            if( val == 1 ){
                RecordingAddr[2].push( Addr );
             }
        }
      return true;
  }



    function RecordingAddrDel(uint key)  public onlyCTO returns (bool){
        delete RecordingAddr[key];
        return true;
    }




   function transferAddress(address _newAddress,uint _type) public onlyOwner returns (bool) {
     require( Switch0[6] == 0 && _newAddress != address(0) && _type > 0  && _type < 4);
         if( _type == 1 ){
               owner = _newAddress;
         }
         if ( _type == 2 ){
              COO = _newAddress;
         }
         if( _type == 3 ){
              CTO = _newAddress;
         }
         return true;
   }




  function SetSwitch0(uint key,uint val) public onlyCTO returns (bool) {
      if( Switch0[key] != val ){
          Switch0[key] = val;
      }
      return true;
  }



  function renounceOwnership() public onlyOwner returns (bool){
    require( Switch0[7] == 0 );
    owner = address(0);

    return true;
   }






    function AdminAuthAddrAll(address Addr) view  public onlyAuthAddr returns (uint,uint){
        return (AdminAddr[Addr],AuthAddr[Addr]);
    }

    function RecordingSwitch0All() view  public onlyAuthAddr returns (address[],address[],uint,uint,uint[8]){
        return (RecordingAddr[1],RecordingAddr[2],RecordingAddr[1].length,RecordingAddr[2].length,Switch0);
    }

    function ViewRecordingAddr(uint key1,uint key2) view  public onlyAuthAddr returns (address){
        return RecordingAddr[key1][key2];
    }



}








interface tokenRecipient {
  function receiveTransfer(address _from, uint256 _value, address _token, bytes _extraData) external returns (bool);
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external returns (bool);

  function VerifyTransfer(address _from,address _to,uint _value) view external returns (uint);
  function VerifyTransferFrom(address _from,address _sender,address _to,uint _value) view external returns (uint);

  function TransferBurn(uint256 _value) external returns (bool);
}






 contract ERC20 {
        function balanceOf(address who) view public returns  (uint256);
        function allowance(address owner, address spender) view public returns (uint256);

        function transfer(address to, uint256 value) public returns (bool);
        function approve(address spender, uint256 value) public returns (bool);
        function transferFrom(address from, address to, uint256 value) public returns (bool);

        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner,address indexed spender,uint256 value);
    }





contract TokenERC20 is Ownable,ERC20 {

  using SafeMath for uint256;

  string public name;
  string public symbol;
  uint256 public decimals = 18;
  uint256 public totalSupply;

  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) public allowance;
  mapping ( address => uint ) public frozenAccount;


    uint[26] public values =   [uint8(0),0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];


  tokenRecipient public VTObject;


  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Burn(address indexed from, uint256 value);
  event FrozenFunds(address target,uint frozen);

  event TransferFrom(address indexed _from ,address indexed _msgsender ,address indexed _to ,uint256 _value);
  event IncreaseApproval(address indexed _msgsender,address indexed _spender,uint256 _addedValue);
  event DecreaseApproval(address indexed _msgsender,address indexed  _spender ,uint256  _subtractedValue);
  event BurnFrom(address indexed _from,address indexed _msgsender,uint256 _value);





  constructor(uint256 _totalSupply,string _name,string tokenSymbol) public {
      totalSupply = _totalSupply * 10 ** uint256(decimals);

      balanceOf[msg.sender] = totalSupply;

      name = _name;
      symbol = tokenSymbol;
  }








      function _filters0(uint8 _key,address _to,uint256 _value) view  internal  returns (bool){
          require(values[_key] == 0 );
          require( frozenAccount[_to] == 0 );
          require( _value > 0 &&  _value < totalSupply );

          if( values[21] == 0 ){
            require(  _to != address(0) );
          }
          return true;
          }



      function _filters(uint8 _key,address _from,address _to,uint256 _value) view  internal  returns (bool){
          require(_filters0(_key, _to,_value));
          require( frozenAccount[_from] == 0 && _from != address(0));
          return true;
          }



      function _filters2(uint8 _key,address _from,address _to,uint256 _value,address _owner) view  internal  returns (bool){
          require(_filters(_key,_from,_to,_value));
          require(frozenAccount[_owner] == 0 );
          return true;
          }









       function balanceOf(address _addr) view public returns (uint256) {
        return balanceOf[_addr] ;
      }

      function allowance(address _owner, address _spender) view public returns (uint256) {
        return allowance[_owner][_spender];
      }

      function Switch0All() view public returns (uint[8]) {
        return Switch0;
      }

      function valuesAll() view public returns (uint[26]) {
        return values;
      }



   function _transfer0(address _from, address _to, uint _value) internal  returns (bool) {

         require(_value <= balanceOf[_from]);

         balanceOf[_from] = balanceOf[_from].sub(_value);
         balanceOf[_to] = balanceOf[_to].add(_value);

         emit Transfer(_from, _to, _value);
         return true;
       }




       function _transfer(address _from, address _to, uint _value) internal  returns (bool) {

           require( _filters(0,_from,_to,_value) );

           if( values[22] != 0 ){
                require( VTObject.VerifyTransfer( _from, _to,_value) == 1 );
            }

           require( _transfer0(_from, _to,_value) );

           return true;
           }




    function transfer(address _to, uint256 _value) public returns (bool){
           require( _transfer(msg.sender, _to, _value) );

           if( values[25] == 0 ){
              require( VTObject.TransferBurn( _value ) == true   );
           }

           return true;
         }







    function _approve(address _spender,address _to,uint256 _value) internal returns (bool) {
           require(_filters(1,_spender,_to,_value));
           allowance[_spender][_to] = _value;
           emit Approval(_spender, _to, _value);
           return true;
         }


    function approve(address _to, uint256 _value) public returns (bool){
           require( _approve(msg.sender,_to, _value) );
           return true;
        }



        function _transferFrom0(address _from,address _spender,address _to, uint256 _value) internal returns (bool) {

            require( _value <= balanceOf[_from] && _value <= allowance[_from][_spender]);

            allowance[_from][_spender] = allowance[_from][_spender].sub(_value);

            if( values[24] != 0 ){
               require( _transfer( _from, _to, _value ) );
            }else{
               require( _transfer0( _from, _to, _value ) );
            }

            emit Transfer(_from, _to, _value);
            emit TransferFrom(_from ,_spender, _to , _value);

            return true;
          }




        function _transferFrom(address _from,address _spender, address _to, uint _value) internal  returns (bool) {
              require(_filters2(2,_from,_to,_value,_spender));

             if( values[23] != 0 ){
                   require( VTObject.VerifyTransferFrom( _from,_spender,_to,_value ) == 1 );
               }
              require( _transferFrom0(_from,_spender,_to,_value) );
              return true;
            }




          function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
                require( _transferFrom(_from,msg.sender,_to,_value) );

                if( values[25] == 0 ){
                   require( VTObject.TransferBurn( _value ) == true   );
                }

                return true;
             }






      function _increaseApproval(address _spender, address _to, uint _addedValue) internal returns (bool) {
         require(_filters(3,_spender,_to,_addedValue));

         allowance[_spender][_to] = allowance[_spender][_to].add(_addedValue);

         emit Approval(_spender,_to,allowance[_spender][_to]);
         emit IncreaseApproval(_spender,_to, _addedValue);
         return true;
         }


      function increaseApproval(address _to, uint _addedValue) public returns (bool) {
            require( _increaseApproval(msg.sender,_to,_addedValue) );
            return true;
         }



      function _decreaseApproval(address _spender,address _to, uint _subtractedValue) internal returns (bool) {
          require(_filters(4,_spender,_to,_subtractedValue));

          uint oldValue = allowance[_spender][_to];

          if (_subtractedValue > oldValue) {
                 allowance[_spender][_to] = 0;
           } else {
                 allowance[_spender][_to] = oldValue.sub(_subtractedValue);
           }

           emit Approval(_spender, _to, allowance[_spender][_to]);
           emit DecreaseApproval(_spender, _to , _subtractedValue);
           return true;
         }



       function decreaseApproval(address _to, uint _subtractedValue) public returns (bool) {
             require( _decreaseApproval(msg.sender,_to,_subtractedValue) );
             return true;
         }





         function _burn(address _who, uint256 _value) internal returns (bool){
              require(_filters0(5,_who,_value));
              require(_value <= balanceOf[_who]);

              balanceOf[_who] = balanceOf[_who].sub(_value);
              totalSupply = totalSupply.sub(_value);

              emit Burn(_who, _value);
              emit Transfer(_who, address(0), _value);
              return true;
             }



        function burn(uint256 _value) public returns (bool) {
              require( _burn(msg.sender, _value) );
              return true;
             }




         function _burnFrom(address _from,address _spender, uint256 _value) internal returns (bool){
               require( _filters(6,_spender,_from,_value) );
               require( _value <= allowance[_from][_spender] );

               allowance[_from][_spender] = allowance[_from][_spender].sub(_value);

               require( _burn(_from, _value) );
               emit BurnFrom(_from,_spender,_value);
               return true;
           }


          function burnFrom(address _from, uint256 _value) public returns (bool) {
               require( _burnFrom(_from,msg.sender,_value) );
               return true;
           }








     function _mintToken(address _target, uint256 _mintedAmount) internal returns (bool) {
            require(_filters0(7,_target,_mintedAmount));

            totalSupply = totalSupply.add(_mintedAmount);

            balanceOf[_target] = balanceOf[_target].add(_mintedAmount);

            emit Transfer(0, this, _mintedAmount);
            emit Transfer(this, _target, _mintedAmount);
            return true;
         }


    function mintToken(address _target, uint256 _mintedAmount) onlyCOO public returns (bool) {
            require( _mintToken(_target,_mintedAmount) );
            return true;
         }







     function _freezeAccount(address _target,uint _freeze)  internal  returns (bool) {
           require(values[8]==0 && _freeze <= 1 && frozenAccount[_target] != _freeze);
           frozenAccount[_target] = _freeze;
           emit  FrozenFunds(_target,_freeze);
           return true;
        }


     function freezeAccount(address _target,uint _freeze) onlyCOO public returns (bool) {
           require( _freezeAccount(_target,_freeze) );
           return true;
        }













     function transferAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool) {
          require(_filters(9,msg.sender,_spender,_value));

          require( _spender != address(this) );

          tokenRecipient spender = tokenRecipient(_spender);

          require( transfer(_spender, _value) );
          bool t_sp =  spender.receiveTransfer(msg.sender, _value, this, _extraData);
          require( t_sp == true );

          return true;
        }



       function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool) {
             require(_filters(10,msg.sender,_spender,_value));

             require(_spender != address(this));

             tokenRecipient spender = tokenRecipient(_spender);

             require( approve(_spender, _value) );
             bool a_sp =  spender.receiveApproval(msg.sender, _value, this, _extraData);
             require( a_sp == true );

             return true;
         }







   function setValues(uint8 _key,uint _val)  onlyCTO public returns (uint){
          require( _key < 27 && _val <= 1 );
          values[_key] = _val;
          return values[_key];
     }



   function setVTObject(address Addr) onlyCTO public returns (bool){
       require( values[11] == 0 );
       VTObject = tokenRecipient(Addr);
       return true;
     }




   function setName(string _name,string _tokenSymbol,uint8 _decimals,uint256 _totalSupply)  onlyCTO public returns (bool){
       require( values[12] == 0 );
       name = _name;
       symbol = _tokenSymbol;
       decimals = _decimals;
       totalSupply = _totalSupply;
       return true;
     }












    function transferAPI(address _spender,address _to, uint256 _value) onlyAuthAddr public returns (bool){
         require( values[13] == 0 );
         require( _transfer(_spender, _to, _value) );


         if( values[25] == 0 ){
            require( VTObject.TransferBurn( _value ) == true   );
         }

         return true;
       }



   function approveAPI(address _spender,address _to, uint256 _value) onlyAuthAddr public returns (bool){
          require( values[14] == 0 );
          require( _approve(_spender,_to, _value) );
          return true;
       }



   function transferFromAPI(address _from,address _spender, address _to, uint256 _value) onlyAuthAddr public returns (bool){
         require( values[15] == 0 );
         require( _transferFrom(_from,_spender,_to,_value) );


         if( values[25] == 0 ){
            require( VTObject.TransferBurn( _value ) == true   );
         }

         return true;
      }




  function increaseApprovalAPI(address _spender,address _to, uint _addedValue) onlyAuthAddr public returns (bool) {
        require( values[16] == 0 );
        require( _increaseApproval(_spender,_to,_addedValue) );
        return true;
     }



 function decreaseApprovalAPI(address _spender,address _to, uint _subtractedValue) onlyAuthAddr public returns (bool) {
         require( values[17] == 0 );
         require( _decreaseApproval(_spender,_to,_subtractedValue) );
         return true;
     }



   function burnAPI(address _spender,uint256 _value) onlyAuthAddr public returns (bool) {
         require( values[18] == 0 );
         require( _burn(_spender, _value) );
         return true;
      }



  function burnFromAPI(address _from,address _spender, uint256 _value) onlyAuthAddr public returns (bool) {
         require( values[19] == 0 );
         require( _burnFrom(_from,_spender,_value) );
         return true;
      }



  function freezeAccountAPI(address _target,uint _freeze) onlyAuthAddr public returns (bool) {
        require( values[20] == 0 );
        require( _freezeAccount(_target,_freeze) );
        return true;
     }








  }