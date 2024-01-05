pragma solidity 0.7.5;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./ChainlinkClient.sol";
import "./Chainlink.sol";

contract BlendExchange is Ownable, ChainlinkClient {
    using SafeMath for uint256;
    using Chainlink for Chainlink.Request;

    event onSwapRequested(
        address indexed user,
        DIRECTION direction,
        uint256 srcAmount,
        bytes32 requestId
    );
    event onSwapDone(
        address indexed user,
        DIRECTION direction,
        uint256 srcAmount,
        uint256 dstAmount,
        bytes32 requestId,
        uint256 nav
    );

    enum DIRECTION {USDC_TO_BLEND, BLEND_TO_USDC}

    struct SwapInfo {
        address owner;
        DIRECTION direction;
        uint256 srcAmount;
        uint256 dstAmount;
        uint256 nav;
        uint256 fee;
        bool exchanged;
    }

    mapping(address => bool) public whitelists;
    mapping(bytes32 => SwapInfo) public swapInfo;
    IERC20 public immutable USDC;
    IERC20 public immutable BLEND;
    uint256 constant NAVTimes = 1e6;
    uint256 public blendFee = 20; // 2%;
    address public oracle;
    bytes32 public jobId;
    uint256 public oracleFee;
    string public api;
    string public path;

    modifier onlyWhitelisted {
        require(whitelists[msg.sender], "Not whitelisted");
        _;
    }

    constructor(
        IERC20 usdc,
        IERC20 blend,
        address _oracle,
        string memory _jobId,
        uint256 _oracleFee,
        string memory _api,
        string memory _path
    ) public {
        USDC = usdc;
        BLEND = blend;
        setPublicChainlinkToken();
        oracle = _oracle;
        jobId = stringToBytes32(_jobId);
        oracleFee = _oracleFee;
        api = _api;
        path = _path;
    }

    function registerWhitelist(address _user) external onlyOwner {
        whitelists[_user] = true;
    }

    function registerWhitelists(address[] memory _users) external onlyOwner {
        for (uint i = 0; i < _users.length; i += 1) {
            whitelists[_users[i]] = true;
        }
    }

    function unregisterWhitelist(address _user) external onlyOwner {
        whitelists[_user] = false;
    }

    function unregisterWhitelists(address[] memory _users) external onlyOwner {
        for (uint i = 0; i < _users.length; i += 1) {
            whitelists[_users[i]] = false;
        }
    }

    function withdrawLiquidity(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOwner {
        _token.transfer(_to, _amount);
    }

    function setBlendFee(uint256 _fee) external onlyOwner {
        blendFee = _fee;
    }

    function setApi(string memory _api, string memory _path)
        external
        onlyOwner
    {
        api = _api;
        path = _path;
    }

    function setOracle(address _oracle) external onlyOwner {
        oracle = _oracle;
    }

    function setOracleFee(uint256 _oracleFee) external onlyOwner {
        oracleFee = _oracleFee;
    }

    function setOracleJobId(string memory _jobId) external onlyOwner {
        jobId = stringToBytes32(_jobId);
    }

    function availableUSDC() public view returns (uint256) {
        return USDC.balanceOf(address(this));
    }

    function availableBLEND() public view returns (uint256) {
        return BLEND.balanceOf(address(this));
    }

    function getEstimateBlendAmount(uint256 usdcAmount, uint256 nav)
        public
        view
        returns (uint256)
    {
        return usdcAmount.mul(1e12).mul(NAVTimes).div(nav); // 1e12 is difference decimals between BLEND and USDC
    }

    function getEstimateUsdcAmount(uint256 blendAmount, uint256 nav)
        public
        view
        returns (uint256, uint256)
    {
        uint256 usdcAmount = blendAmount.mul(nav).div(NAVTimes).div(1e12); // 1e12 is difference decimals between BLEND and USDC
        uint256 fee = usdcAmount.mul(blendFee).div(1000);
        return (usdcAmount.sub(fee), fee);
    }

    function _requestNAV() internal returns (bytes32) {
        Chainlink.Request memory request =
            buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

        // Set the URL to perform the GET request on
        request.add("get", api);
        request.add("path", path);
        return sendChainlinkRequestTo(oracle, request, oracleFee);
    }

    function swapUsdcToBlend(uint256 usdcAmount) external onlyWhitelisted {
        require(usdcAmount > 0, "invalid amount");
        USDC.transferFrom(msg.sender, address(this), usdcAmount);

        bytes32 requestId = _requestNAV();
        swapInfo[requestId] = SwapInfo({
            owner: msg.sender,
            direction: DIRECTION.USDC_TO_BLEND,
            srcAmount: usdcAmount,
            dstAmount: 0,
            nav: 0,
            fee: 0,
            exchanged: false
        });

        emit onSwapRequested(
            msg.sender,
            DIRECTION.USDC_TO_BLEND,
            usdcAmount,
            requestId
        );
    }

    function swapBlendToUsdc(uint256 blendAmount) external onlyWhitelisted {
        require(blendAmount > 0, "invalid amount");
        BLEND.transferFrom(msg.sender, address(this), blendAmount);

        bytes32 requestId = _requestNAV();
        swapInfo[requestId] = SwapInfo({
            owner: msg.sender,
            direction: DIRECTION.BLEND_TO_USDC,
            srcAmount: blendAmount,
            dstAmount: 0,
            nav: 0,
            fee: 0,
            exchanged: false
        });

        emit onSwapRequested(
            msg.sender,
            DIRECTION.BLEND_TO_USDC,
            blendAmount,
            requestId
        );
    }

    /**
     * Receive the response in the form of uint256
     */
    function fulfill(bytes32 _requestId, uint256 _nav)
        public
        recordChainlinkFulfillment(_requestId)
    {
        SwapInfo storage info = swapInfo[_requestId];
        require(info.exchanged == false, "already exchanged");
        if (info.direction == DIRECTION.USDC_TO_BLEND) {
            uint256 blendAmount = getEstimateBlendAmount(info.srcAmount, _nav);
            BLEND.transfer(info.owner, blendAmount);
            info.dstAmount = blendAmount;
        } else {
            (uint256 usdcAmount, uint256 fee) =
                getEstimateUsdcAmount(info.srcAmount, _nav);
            USDC.transfer(info.owner, usdcAmount);
            info.fee = fee;
            info.dstAmount = usdcAmount;
        }
        emit onSwapDone(
            info.owner,
            info.direction,
            info.srcAmount,
            info.dstAmount,
            _requestId,
            _nav
        );
        info.nav = _nav;
        info.exchanged = true;
    }

    function stringToBytes32(string memory source)
        internal
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
}
