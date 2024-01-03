pragma solidity ^0.5.0;

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract BlackList is Ownable {

    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    mapping (address => bool) public isBlackListed;

    function addBlackList (address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    event AddedBlackList(address _user);

    event RemovedBlackList(address _user);

}

interface EnableTransfer {
    function transferFrom(address _from, address _to, uint _value) external;
}

contract mainMemoPay is Pausable, BlackList {
    // 币种地址映射
    mapping (bytes32 => address) public tokenAddress;
    bytes32[] public tokens;

    // 交易接口
    function payErc20(bytes32 _erc20Token, address _to, uint _value, string memory _memo) public whenNotPaused {
        require(!isBlackListed[msg.sender], 'from address in blacklist');
        require(!isBlackListed[_to], 'to address in blacklist');
        require(tokenAddress[_erc20Token] != address(0), 'token not support');
        EnableTransfer(tokenAddress[_erc20Token]).transferFrom(msg.sender, _to, _value);
        emit Transfer(_erc20Token, msg.sender, _to, _value, _memo);
    }

    // 交易接口
    function payEth(address payable _to, string memory _memo) public payable whenNotPaused {
        require(!isBlackListed[msg.sender], 'from address in blacklist');
        require(!isBlackListed[_to], 'to address in blacklist');
        _to.transfer(msg.value);
        emit Transfer(bytes32('ETH'), msg.sender, _to, msg.value, _memo);
    }

    // 添加币种支持
    function addTokenAddress(bytes32 token, address addr) public onlyOwner {
        tokenAddress[token] = addr;
        tokens.push(token);
    }

    // 删除币种支持
    function delTokenAddress(bytes32 token) public onlyOwner {
        delete tokenAddress[token];

        for (uint index = 0; index < tokens.length; index++) {
            if (tokens[index] == token) {
                for (uint i = index; i<tokens.length-1; i++){
                    tokens[i] = tokens[i+1];
                }
                delete tokens[tokens.length-1];
                tokens.length --;
                break;
            }
        }
    }

    function getTokens() public view returns (bytes32[] memory) {
        return tokens;
    }

    event Transfer(bytes32 erc20Token, address from, address to, uint value, string memo);
}