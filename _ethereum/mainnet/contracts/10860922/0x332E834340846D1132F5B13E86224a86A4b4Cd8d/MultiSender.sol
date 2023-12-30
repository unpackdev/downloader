/**
 *Submitted for verification at Etherscan.io on 2020-08-22
*/

pragma solidity 0.6.0;

interface Token {
  function transfer(address to, uint256 value) external returns (bool);
  function balanceOf(address owner) external view returns (uint256 balance);
}

contract Ownable {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract MultiSender is Ownable {

    Token _token;

    event TransferredToken(address indexed to, uint256 value);
    event FailedTransfer(address indexed to, uint256 value);


    modifier whenDropIsActive() {
        require(isActive());
        _;
    }

    constructor () public {
        address _tokenAddr = 0xdAC17F958D2ee523a2206206994597C13D831ec7; 
        _token = Token(_tokenAddr);
    }

    function sendTokens(address[] calldata dests, uint256[] calldata values) external whenDropIsActive onlyOwner {
        for (uint256 i = 0; i < dests.length; i++) {
            sendInternally(dests[i], values[i]);
        } 
    }

    function destroy(address payable owner) public onlyOwner {
        uint256 balance = tokensAvailable();
        require(balance > 0, "balance is zero");
        _token.transfer(owner, balance);
        selfdestruct(owner);
    }

    function isActive() public view returns (bool) {
        return (tokensAvailable() > 0);
    }

    function tokensAvailable() public view returns (uint256) {
        return _token.balanceOf(address(this));
    }

    function sendInternally(address recipient, uint256 tokensToSend) internal {
        if (recipient == address(0)) return;

        if (tokensAvailable() >= tokensToSend) {
            _token.transfer(recipient, tokensToSend);
            emit TransferredToken(recipient, tokensToSend);
        } else {
            emit FailedTransfer(recipient, tokensToSend); 
        }
    }
}