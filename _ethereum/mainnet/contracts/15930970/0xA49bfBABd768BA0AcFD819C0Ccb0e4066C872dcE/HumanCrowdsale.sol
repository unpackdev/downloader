// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./SafeMath.sol";
import "./AccessControl.sol";
import "./PullPayment.sol";
import "./Ownable.sol";
import "./Human.sol";
import "./Signer.sol";
import "./Teaser.sol";

contract HumanCrowdsale is AccessControl, PullPayment, Ownable, Signer {
    using SafeMath for uint256;
    bytes32 public constant CROWD_ROLE = keccak256("CROWD_ROLE");
    address public token;
    address public teaser;
    HumanState public state;

    uint256 public oLimit = 2; //own mint limit
    uint256 public aLimit = 2500; //allow mining limit
    uint256 public mLimit = 4000; //total mining limit

    uint256 public allowPrice = 0.25 ether;
    uint256 public salePrice = 0.3 ether;
    address public collector;
    uint256 public mAmount = 200;
    mapping(address => uint) mintNum;
    enum HumanState {
        PRE,
        ALLOW,
        PUBLIC,
        SALE,
        FINISH
    }

    event HumanStateChange(HumanState state);
    event SalePriceChanged(uint256 price);
    event AllowPriceChanged(uint256 price);
    event MLimitChanged(uint256 mLimit);
    event CollectorChanged(address collector);
    event OLimitChanged(uint256 oLimit);

    constructor(
        address _collector,
        address _nft,
        address _teaser
    ) Signer(Human(_nft).symbol()) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CROWD_ROLE, msg.sender);
        collector = _collector;
        setNft(_nft);
        setTeaser(_teaser);
        setSigningKey(msg.sender);
    }
    modifier isState(HumanState _state) {
        require(state == _state, "HumanCrowdsale: Wrong state for this action");
        _;
    }
    function allowMint(uint256 _amount, bytes calldata _signature)
        external
        payable
    isState(HumanState.ALLOW)
    requiresSignature(_signature)
    {
        require(
            mintNum[msg.sender].add(_amount) <= oLimit,
            "HUMANCROWDSALE:Exceeded the own limit"
        );
        uint256 tAmount = Teaser(teaser).balanceOf(msg.sender);
        require(
            tAmount >=5,
            "HUMANCROWDSALE:Not eligible for purchase"
        );
        require(
            msg.value == _amount.mul(allowPrice),
            "HUMANCROWDSALE:Payment declined"
        );
        mAmount = mAmount.add(_amount);
        require(
            mAmount <= aLimit,
            "HUMANCROWDSALE:Sold out in this state"
        );

        _asyncTransfer(collector, msg.value);
        mintNum[msg.sender]=mintNum[msg.sender].add(_amount);
        Human(token).mint(msg.sender, _amount);
    }

    function mint(uint256 _amount) external payable {
        require(state == HumanState.PUBLIC || state == HumanState.SALE, "HumanCrowdsale: Wrong state for this action");
        require(mintNum[msg.sender].add(_amount) <= oLimit,"HUMANCROWDSALE:Exceeded the own limit");


        uint256 tAmount = Teaser(teaser).balanceOf(msg.sender);
        if(state == HumanState.PUBLIC ){
            require(msg.value == _amount.mul(allowPrice),"HUMANCROWDSALE:Payment declined");
            require(tAmount >= 5,"HUMANCROWDSALE:Not eligible for purchase");
        }else{
            require(msg.value == _amount.mul(salePrice),"HUMANCROWDSALE:Payment declined");
            require(tAmount > 0,"HUMANCROWDSALE:Not eligible for purchase");
        }

        mAmount = mAmount.add(_amount);
        require(mAmount <= mLimit, "HUMANCROWDSALE:Exceeded the total amount of mining");

        _asyncTransfer(collector, msg.value);
        mintNum[msg.sender]=mintNum[msg.sender].add(_amount);
        Human(token).mint(msg.sender, _amount);
    }

    function setNft(address _nft) public onlyRole(CROWD_ROLE) {
        require(_nft != address(0), "HUMANCROWDSALE:Invalid address");
        token = _nft;
    }

    function setTeaser(address _teaser) public onlyRole(CROWD_ROLE) {
        require(_teaser != address(0), "HUMANCROWDSALE:Invalid address");
        teaser = _teaser;
    }

    function setState(HumanState _state) external onlyRole(CROWD_ROLE) {
        state = _state;
        emit HumanStateChange(_state);
    }
    function setOLimit(uint256 _oLimit) external onlyRole(CROWD_ROLE) {
        oLimit = _oLimit;
        emit OLimitChanged(oLimit);
    }
    function setALimit(uint256 _aLimit) external onlyRole(CROWD_ROLE) {
        aLimit = _aLimit;
    }
    function setMLimit(uint256 _mLimit) external onlyRole(CROWD_ROLE) {
        mLimit = _mLimit;
        emit MLimitChanged(mLimit);
    }
    function setWhitePrice(uint256 _salePrice) external onlyRole(CROWD_ROLE) {
        salePrice = _salePrice;
        emit SalePriceChanged(_salePrice);
    }
    function setAllowPrice(uint256 _allowPrice) external onlyRole(CROWD_ROLE) {
        allowPrice = _allowPrice;
        emit AllowPriceChanged(_allowPrice);
    }
    function totalMinted() external view returns (uint256) {
        return mAmount;
    }
    function canMint(address addr) external view returns (uint256) {
        if(HumanState.ALLOW == state || HumanState.PUBLIC == state ){
            uint256 tAmount = Teaser(teaser).balanceOf(addr);
            if(tAmount >=5){
                return oLimit>mintNum[addr]?oLimit.sub(mintNum[addr]):0;
            }
        }else if(HumanState.SALE == state ){
            uint256 tAmount = Teaser(teaser).balanceOf(addr);
            if(tAmount >0){
                return oLimit>mintNum[addr]?oLimit.sub(mintNum[addr]):0;
            }
        }
        return 0;
    }

    function saleState() external  view returns (HumanState,uint256) {
        if(state == HumanState.ALLOW ||state == HumanState.PUBLIC){
            return (state,allowPrice);
        }else if(state == HumanState.SALE){
            return (state,salePrice);
        }
        return (state,0);
    }
    function setCollector(address _collector) external onlyOwner {
        require(_collector != address(0), "HUMANCROWDSALE:Invalid address");
        collector = _collector;
        emit CollectorChanged(collector);
    }
    function transferRoleAdmin(address newDefaultAdmin)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            newDefaultAdmin != address(0),
            "HUMANCROWDSALE:Invalid address"
        );
        _setupRole(DEFAULT_ADMIN_ROLE, newDefaultAdmin);
    }
}
