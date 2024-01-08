//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
import "./ERC1155.sol";

interface DevopsCard{
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
  function transfer(address _to, uint256 _value) external;
}

contract WrappedDevopsCard is ERC1155 {
    using SafeMath for uint256;
    using Address for address;
    string metadataURI="";

    bytes4 constant private INTERFACE_SIGNATURE_URI = 0x0e89341c;
    // id => contracts
    address[] contracts=[
        0x16b262b66E300C7410f0771eAC29246A75fb8c48 //1
    ];

    
    address public owner;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    function supportsInterface(bytes4 _interfaceId) override
    public
    pure
    returns (bool) {
        if (_interfaceId == INTERFACE_SIGNATURE_URI) {
            return true;
        } else {
            return super.supportsInterface(_interfaceId);
        }
    }

    function mint(uint256 _id, address  _to, uint256  _quantity) internal {

            // Grant the items to the caller
            balances[_id][_to] = _quantity.add(balances[_id][_to]);

            // Emit the Transfer/Mint event.
            // the 0x0 source address implies a mint 
            // It will also provide the circulating supply info.
            emit TransferSingle(msg.sender, address(0x0), _to, _id, _quantity);

            if (_to.isContract()) {
                _doSafeTransferAcceptanceCheck(msg.sender, msg.sender, _to, _id, _quantity, '');
            }
    }

    function wrap(uint256 id,uint256 amount) public{
        require(id == 1);
        uint256 index = id-1;
        address contractaddress = contracts[index];
        DevopsCard cards=DevopsCard(contractaddress);
        require(cards.transferFrom(msg.sender,address(this),amount));
        mint(id,msg.sender,amount);
    }

    function unwrap(uint256 id,uint256 amount) public{
        require(id==1);
        require(balances[id][msg.sender]>=amount);
        uint256 index = id-1;
        address contractaddress = contracts[index];
        DevopsCard cards=DevopsCard(contractaddress);
        balances[id][msg.sender] = balances[id][msg.sender].sub(amount);
        cards.transfer(msg.sender,amount);
        emit TransferSingle(address(0x0),msg.sender, msg.sender,id , amount);
    }

    function setBaseURI(string calldata _uri) public onlyOwner{
        metadataURI=_uri;
    }

    function uri(uint256) public view returns (string memory) {
        return metadataURI;
    }
}

