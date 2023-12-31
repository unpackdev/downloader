pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

interface IGMXAdapter {
    struct IncreasePositionRequest {
        address _jasperVault;
        string _integrationName;
        address[] _path;
        address _indexToken;
        uint256 _amountIn;
        int256 _amountInUnits;
        uint256 _minOut;
        uint256 _minOutUnits;
        uint256 _sizeDelta;
        uint256 _sizeDeltaUnits;
        bool _isLong;
        uint256 _acceptablePrice;
        uint256 _executionFee;
        bytes32 _referralCode;
        address _callbackTarget;
        bytes _data;
    }
    struct DecreasePositionRequest {
        string _integrationName;
        address[] _path;
        address _indexToken;
        uint256 _collateralDelta;
        int256 _collateralUnits;
        uint256 _sizeDelta;
        int256 _sizeDeltaUnits;
        bool _isLong;
        address _receiver;
        uint256 _acceptablePrice;
        uint256 _minOut;
        uint256 _minOutUnits;
        uint256 _executionFee;
        bool _withdrawETH;
        address _callbackTarget;
        bytes _data;
    }
    struct SwapData {
        address _jasperVault;
        string _integrationName;
        address[] _path;
        uint256 _amountIn;
        int256 _amountInUnits;
        uint256 _minOut;
        uint256 _minOutUnits;
        uint256 _swapType;
        address _receiver;
        bytes _data;
    }
    struct IncreaseOrderData {
        string _integrationName;
        address[] _path;
        uint256 _amountIn;
        int256 _amountInUnits;
        uint256 _leverage;
        address _indexToken;
        uint256 _minOut;
        uint256 _minOutUnits;
        uint256 _sizeDelta;
        uint256 _sizeDeltaUnits;
        address _collateralToken;
        bool _isLong;
        uint256 _triggerPrice;
        bool _triggerAboveThreshold;
        uint256 _executionFee;
        bool _shouldWrap;
        uint256 _fee;
        bytes _data;
    }
    struct DecreaseOrderData {
        string _integrationName;
        address _indexToken;
        uint256 _sizeDelta;
        uint256 _sizeDeltaUnits;
        address _collateralToken;
        uint256 _collateralDelta;
        uint256 _collateralDeltaUnits;
        bool _isLong;
        uint256 _triggerPrice;
        bool _triggerAboveThreshold;
        uint256 _fee;
        bytes _data;
    }

    struct HandleRewardData {
        string _integrationName;
        bool _shouldClaimGmx;
        bool _shouldStakeGmx;
        bool _shouldClaimEsGmx;
        bool _shouldStakeEsGmx;
        bool _shouldStakeMultiplierPoints;
        bool _shouldClaimWeth;
        bool _shouldConvertWethToEth;
        bytes _data;
    }

    struct CreateOrderData {
        string _integrationName;
        bool _isLong;
        bytes _positionData;
    }

    struct StakeGMXData {
        address _collateralToken;
        int256 _underlyingUnits;
        uint256 _amount;
        string _integrationName;
        bool _isStake;
        bytes _positionData;
    }

    struct StakeGLPData {
        address _token;
        int256 _amountUnits;
        uint256 _amount;
        uint256 _minUsdg;
        uint256 _minUsdgUnits;
        uint256 _minGlp;
        uint256 _minGlpUnits;
        bool _isStake;
        string _integrationName;
        bytes _data;
    }

    function ETH_TOKEN() external view returns (address);

    function getInCreasingPositionCallData(
        IncreasePositionRequest memory request
    )
        external
        view
        returns (address _subject, uint256 _value, bytes memory _calldata);

    function getDeCreasingPositionCallData(
        DecreasePositionRequest memory request
    )
        external
        view
        returns (address _subject, uint256 _value, bytes memory _calldata);

    function PositionRouter() external view returns (address);

    function OrderBook() external view returns (address);

    function Vault() external view returns (address);

    function GMXRouter() external view returns (address);

    function StakedGmx() external view returns (address);

    function GlpRewardRouter() external view returns (address);

    function getTokenBalance(
        address _token,
        address _jasperVault
    ) external view returns (uint256);

    function getCreateDecreaseOrderCallData(
        DecreaseOrderData memory data
    ) external view returns (address, uint256, bytes memory);

    function getCreateIncreaseOrderCallData(
        IncreaseOrderData memory data
    ) external view returns (address, uint256, bytes memory);

    function getSwapCallData(
        SwapData memory data
    ) external view returns (address, uint256, bytes memory);

    function approvePositionRouter()
        external
        view
        returns (address, uint256, bytes memory);

    function IsApprovedPlugins(
        address jasperVault
    ) external view returns (bool);

    function getStakeGMXCallData(
        address _jasperVault,
        uint256 _stakeAmount,
        bool _isStake,
        bytes calldata _data
    )
        external
        view
        returns (address _subject, uint256 _value, bytes memory _calldata);

    function getStakeGLPCallData(
        address _jasperVault,
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp,
        bool _isStake,
        bytes calldata _data
    )
        external
        view
        returns (address _subject, uint256 _value, bytes memory _calldata);

    function getHandleRewardsCallData(
        HandleRewardData memory data
    )
        external
        view
        returns (address _subject, uint256 _value, bytes memory _calldata);
}
