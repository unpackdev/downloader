// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "./MerkleProof.sol";

interface _ISwapPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface _IERC20{
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint256);
    function totalSupply() external view returns(uint256);

    function balanceOf(address account) external view returns(uint256);
    function allowance(address deployer, address spender) external view returns(uint256);

    function approve(address _spender, uint256 _value) external returns(bool);
    function transfer(address _to, uint256 _value) external returns(bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns(bool);

    event Approval(address indexed deployer, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

library SafeMath {
    // ==================================================
    // *
    // ==================================================
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    // ==================================================
    // /
    // ==================================================
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    // ==================================================
    // %
    // ==================================================
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }

    // ==================================================
    // -
    // ==================================================
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    // ==================================================
    // +
    // ==================================================
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    // ==================================================
    // Inspired by OraclizeAPI's implementation - MIT licence
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
    // ==================================================
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

contract CoinDao is _IERC20{

    using SafeMath for uint256;

    /// param ///

    address public onlyOwner;
    address private teamWallet = address(0xf25F2458f00ac54b91a539EA2d476C6245B51A27);
    address private airdropWallet = address(0);

    _IERC20 private swapTokenObject;
    uint256 private swapTokenDecimal;

    address public pricePair;                         // get price
    mapping (address => bool) public pairOf;          // address => true

    bytes32 public merkleRoot;
    uint256 public maxSellNumber;
    uint256 public updateInterval = 10;
    uint256 public lastUpdateTime;
    uint256 public lastUpdatePrice;                      // Now token price (Price / 1000000000 = $U)

    bool public freeTransfer = false;
    mapping (address => uint256) public costOf;          // address => cost
    
    uint256 public claimBase = 12500;
    uint256 public claimPremium = 10;                    // airdrop cost premium
    mapping (address => uint) public claimedOf;          // address => cost

    enum buyOrSell{buy, sell}

    /// contract ///

    string private _name = "CoinDao";
    string private _symbol = "CO";

    uint256 private _decimals = 18;
    uint256 private _totalSupply = 210000000 * (10 ** _decimals);

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    constructor() {
        onlyOwner = msg.sender;

        uint256 ratioValue = _totalSupply.div(100);
        _balances[onlyOwner] = ratioValue.mul(10);
        _balances[teamWallet] = ratioValue.mul(10);
        _balances[airdropWallet] = ratioValue.mul(80);
        emit Transfer(airdropWallet, onlyOwner, _balances[onlyOwner]);
        emit Transfer(airdropWallet, teamWallet, _balances[teamWallet]);

        setMaxSellNumber(ratioValue.mul(5));
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view virtual override returns (uint256) {
        return _balances[_owner];
    }

    function allowance(address _owner, address _spender) public view virtual override returns (uint256) {
        return _allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _value) public virtual override returns(bool){
        _approve(msg.sender, _spender, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) public virtual override returns(bool){
        return transferFrom(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public virtual override returns(bool){
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");

        if(_from != msg.sender && pairOf[_from] == false){
            require(maxSellNumber == 0 || maxSellNumber >= _value, "Exceeds the maximum sellable quantity for a single transaction");
        }

        // check allowance
        if(_from != msg.sender){
            uint256 currentAllowance = _allowances[_from][msg.sender];
            require(currentAllowance >= _value, "ERC20: transfer amount exceeds allowance");
            _approve(_from, msg.sender, currentAllowance.sub(_value));
        }

        // sell or transfer
        if(pairOf[_from] == false && freeTransfer == false){
            uint256 canSellPrice = costOf[_from];
            if(canSellPrice > lastUpdatePrice){
                uint256 lossRatio = canSellPrice.sub(lastUpdatePrice).mul(100).div(canSellPrice);
                if(lossRatio == 0){
                    lossRatio = 1;
                }
                revert(string.concat("Position Losses(-", lossRatio.toString(), "%), Can't sell or transfer"));
            }
        }

        _transfer(_from, _to, _value, 0);
        updateTokenPrice();
        return true;
    }

    function _approve(address _owner, address _spender, uint256 _value) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][_spender] = _value;
        emit Approval(_owner, _spender, _value);
    }

    function _transfer(address _from, address _to, uint256 _value, uint256 _cost) private {
        require(_value > 0 && _balances[_from] >= _value);

        // Update Balance/Cost
        updateBalanceAndCost(_from, _value, _cost, buyOrSell.sell);
        updateBalanceAndCost(_to, _value, _cost, buyOrSell.buy);

        emit Transfer(_from, _to, _value);
    }

    /// Func ///

    /**
     * @notice Update balance/cost, and make transfer
     * @param _address   Change of address
     * @param _changeQty Change of qty
     * @param _cost      Buy/sell costs
     * @param _action    Change direction (buy or sell)
     */
    function updateBalanceAndCost(address _address, uint256 _changeQty, uint256 _cost, buyOrSell _action) private {
        if(_cost == 0){
            _cost = lastUpdatePrice;
        }
        uint256 changeAmount = _changeQty.mul(_cost);

        uint256 originQty = _balances[_address];
        uint256 originAmount = originQty.mul(costOf[_address]);

        uint256 finallyQty;
        uint256 finallyCost;
        if(_action == buyOrSell.buy){
            // + (originAmount ＋ changeAmount) ／ finallyQty
            finallyQty = originQty.add(_changeQty);
            finallyCost = originAmount.add(changeAmount).div(finallyQty);
        }else{
            // - (originAmount - changeAmount) ／ finallyQty
            finallyQty = originQty.sub(_changeQty);
            if(originAmount <= changeAmount){
                finallyCost = 0;
            }else{
                finallyCost = originAmount.sub(changeAmount).div(finallyQty);
            }
        }
        
        costOf[_address] = finallyCost;
        _balances[_address] = finallyQty;
    }

    /**
     * @notice Update Token Price
     */
    function updateTokenPrice() private {
        uint256 _timestamp = block.timestamp;
        if(_timestamp.sub(lastUpdateTime) < updateInterval || pricePair == address(0)){
            return;
        }

        uint256 selfBalance = _balances[pricePair];
        uint256 otherBalance = swapTokenObject.balanceOf(pricePair);

        // same decimal
        if (_decimals < swapTokenDecimal){
            selfBalance = selfBalance.mul(10 ** swapTokenDecimal.sub(_decimals));
        }else if(_decimals > swapTokenDecimal){
            otherBalance = otherBalance.mul(10 ** _decimals.sub(swapTokenDecimal));
        }

        lastUpdateTime = _timestamp;
        lastUpdatePrice = otherBalance.mul(10 ** 9).div(selfBalance);
    }

    /// Manager ///

    modifier _manager(){
        require(onlyOwner == msg.sender, "Permission denied");
        _;
    }

    function setOwner(address newOwner) _manager public {
        onlyOwner = newOwner;
    }

    function setFreeTransfer(bool _bool) _manager public { 
        freeTransfer = _bool;
    }

    function setMaxSellNumber(uint256 _value) _manager public {
        maxSellNumber = _value;
    }

    function setUpdateInterval(uint256 _interval) _manager public { 
        updateInterval = _interval;
    }

    function setPricePair(address _address) _manager public {
        if(_address != address(0)){
            _ISwapPair pair = _ISwapPair(_address);
            address token0 = pair.token0();
            address token1 = pair.token1();
            address selfAddress = address(this);
            require(token0 == selfAddress || token1 == selfAddress, "Swap pair error");

            swapTokenObject = _IERC20(token0 != selfAddress ? token0 : token1);
            swapTokenDecimal = swapTokenObject.decimals();
            setPairOf(_address, true);
        }
        pricePair = _address;
    }

    function setPairOf(address _address, bool _bool) _manager public {
        pairOf[_address] = _bool;
    }

    function setMerkleRoot(bytes32 _merkleRoot) _manager public {
        merkleRoot = _merkleRoot;
    }

    function setClaimBase(uint256 _number) _manager public {
        claimBase = _number;
    }

    function setClaimPremium(uint256 _ratio) _manager public {
        claimPremium = _ratio;
    }

    /// Airdrop ///

    function getPosition(address _address) public view returns (uint256, uint256){
        return (costOf[_address], _balances[_address]);
    }

    function getClaim(address _address) public view returns (uint256, uint256){
        return (_balances[airdropWallet].div(claimBase), claimedOf[_address]);
    }

    function claim(bytes32[] calldata proof) public {
        (uint256 claimValue, uint256 claimedValue) = getClaim(msg.sender);
        require(claimValue > 0, "Suspension of claim");
        require(claimedValue == 0, "Already claimed");
        claimedOf[msg.sender] = claimValue;

        // check merkle
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Address not in WhiteList");
        
        // check premium
        uint256 premiumCost = 0;
        if(lastUpdatePrice > 0 && claimPremium > 0){
            premiumCost = lastUpdatePrice.div(100).mul(100 + claimPremium);
        }
        _transfer(airdropWallet, msg.sender, claimValue, premiumCost);
    }

    function donate(uint256 _value) public {
        _transfer(msg.sender, airdropWallet, _value, 0);
    }

}

