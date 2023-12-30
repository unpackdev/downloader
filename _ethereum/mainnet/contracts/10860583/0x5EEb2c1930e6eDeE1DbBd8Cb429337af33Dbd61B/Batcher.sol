pragma solidity >=0.6.0 <0.7.0;

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

contract Batcher is Ownable {

    Token token;

    event TokenActivated(address tokenAddress, uint256 value);
    event TransferredToken(address indexed to, uint256 value);
    event FailedTransfer(address indexed to, uint256 value);

    modifier whenDropIsActive() {
        require(isActive());
        _;
    }

    constructor () public {
        
    }
    
    
    
    function isActive() public view returns (bool) {
        return (address(token) != address(0)) && (tokensAvailable() > 0);
    }
    
    function tokensAvailable() public view returns (uint256) {
        if (address(token) == address(0)) {
            return 0;
        }
        return token.balanceOf(address(this));
    }
    
    
    
    function sendTokens(address[] calldata dests, uint256[] calldata values) external whenDropIsActive onlyOwner {
        for (uint256 i = 0; i < dests.length; i++) {
            sendInternally(dests[i], values[i]);
        }
    }
    
    function sendBackRest() public whenDropIsActive onlyOwner {
        uint256 balance = tokensAvailable();
        if(balance > 0) {
            token.transfer(_owner, balance);
        }
    }
    
    
    
    function setToken(address _tokenAddress) public onlyOwner {
        //sendBackRest();
        token = Token(_tokenAddress);
        emit TokenActivated(_tokenAddress, tokensAvailable());
    }

    
    function destroy(address payable owner) public onlyOwner {
        uint256 balance = tokensAvailable();
        require(balance > 0, "balance is zero");
        token.transfer(owner, balance);
        selfdestruct(owner);
    }

    


    function sendInternally(address recipient, uint256 tokensToSend) internal {
        if (recipient == address(0)) return;

        if (tokensAvailable() >= tokensToSend) {
            token.transfer(recipient, tokensToSend);
            emit TransferredToken(recipient, tokensToSend);
        } else {
            emit FailedTransfer(recipient, tokensToSend);
        }
    }
}