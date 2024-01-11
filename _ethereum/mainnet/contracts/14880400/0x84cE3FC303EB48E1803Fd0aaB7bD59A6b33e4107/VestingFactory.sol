// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./TransferHelper.sol";
import "./LinearVesting.sol";
import "./IFeeManager.sol";
import "./IReferralManager.sol";
import "./IMinimalProxy.sol";
import "./TransferHelper.sol";
import "./CloneBase.sol";

contract VestingFactory is Ownable, CloneBase {
    using SafeMath for uint256;

    event VestingLaunched(uint256 _id, address _vestingContract);
    event ImplementationLaunched(uint256 _id, address _implementation);
    event ImplementationUpdated(uint256 _id, address _implementation);

    address[] public linearVestings;

    IFeeManager public feeManager;

    //Trigger for ReferralManager mode
    bool public isReferralManagerEnabled;

    IReferralManager public referralManager;
    mapping(uint256 => address) public implementationIdVsImplementation;
    uint256 public nextId;

    function addImplementation(address _newImplementation) external onlyOwner {
        require(_newImplementation != address(0), "Invalid implementation");
        implementationIdVsImplementation[nextId] = _newImplementation;

        emit ImplementationLaunched(nextId, _newImplementation);

        nextId = nextId.add(1);
    }

    function updateImplementation(uint256 _id, address _newImplementation)
        external
        onlyOwner
    {
        address currentImplementation = implementationIdVsImplementation[_id];
        require(currentImplementation != address(0), "Incorrect Id");

        implementationIdVsImplementation[_id] = _newImplementation;
        emit ImplementationUpdated(_id, _newImplementation);
    }

    function _launchVesting(uint256 _id, bytes memory _encodedData)
        internal
        returns (address)
    {
        address _erc20Token;

        (_erc20Token) = abi.decode(_encodedData, (address));
        require(address(_erc20Token) != address(0), "Incorrect token address");

        address linearVestingLib = implementationIdVsImplementation[_id];
        require(linearVestingLib != address(0), "Incorrect Id");

        address linearVesting = createClone(linearVestingLib);

        IMinimalProxy(linearVesting).init(_encodedData);

        linearVestings.push(linearVesting);

        emit VestingLaunched(_id, linearVesting);

        return address(linearVesting);
    }

    function _handleFeeManager()
        private
        returns (uint256 feeAmount_, address feeToken_)
    {
        require(address(feeManager) != address(0), "Add FeeManager");
        (feeAmount_, feeToken_) = getFeeInfo();
        if (feeToken_ != address(0)) {
            TransferHelper.safeTransferFrom(
                feeToken_,
                msg.sender,
                address(this),
                feeAmount_
            );

            TransferHelper.safeApprove(
                feeToken_,
                address(feeManager),
                feeAmount_
            );

            feeManager.fetchFees();
        } else {
            require(msg.value == feeAmount_, "Invalid value sent for fee");
            feeManager.fetchFees{value: msg.value}();
        }

        return (feeAmount_, feeToken_);
    }

    function getFeeInfo() public view returns (uint256, address) {
        return feeManager.getFactoryFeeInfo(address(this));
    }

    function _handleReferral(address referrer, uint256 feeAmount) private {
        if (isReferralManagerEnabled && referrer != address(0)) {
            referralManager.handleReferralForUser(
                referrer,
                msg.sender,
                feeAmount
            );
        }
    }

    function launchVesting(uint256 _id, bytes memory _encodedData)
        external
        payable
        returns (address)
    {
        address vestingAddress = _launchVesting(_id, _encodedData);
        _handleFeeManager();
        return vestingAddress;
    }

    function launchVestingWithReferral(
        uint256 _id,
        address _referrer,
        bytes memory _encodedData
    ) external payable returns (address) {
        address vestingAddress = _launchVesting(_id, _encodedData);
        (uint256 feeAmount, ) = _handleFeeManager();
        _handleReferral(_referrer, feeAmount);

        return vestingAddress;
    }

    function updateFeeManager(address _feeManager) external onlyOwner {
        require(_feeManager != address(0), "Fee Manager address cant be zero");
        feeManager = IFeeManager(_feeManager);
    }

    function updateReferralManagerMode(
        bool _isReferralManagerEnabled,
        address _referralManager
    ) external onlyOwner {
        require(
            _referralManager != address(0),
            "Referral Manager address cant be zero"
        );
        isReferralManagerEnabled = _isReferralManagerEnabled;
        referralManager = IReferralManager(_referralManager);
    }

    function withdrawERC20(IERC20 _token) external onlyOwner {
        TransferHelper.safeTransfer(
            address(_token),
            msg.sender,
            _token.balanceOf(address(this))
        );
    }
}
