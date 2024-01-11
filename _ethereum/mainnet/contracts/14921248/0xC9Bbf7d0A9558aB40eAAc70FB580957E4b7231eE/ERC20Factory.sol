// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./ERC20Lib.sol";
import "./IFeeManager.sol";
import "./TransferHelper.sol";
import "./CloneBase.sol";
import "./IReferralManager.sol";
import "./IMinimalProxy.sol";
import "./Ownable.sol";

contract ERC20Factory is Ownable, CloneBase {
    using SafeMath for uint256;

    event ERC20Created(uint256 _id, address _erc20Contract);
    event ImplementationLaunched(uint256 _id, address _implementation);
    event ImplementationUpdated(uint256 _id, address _implementation);

    address[] public erc20Contracts;

    mapping(uint256 => address) public implementationIdVsImplementation;

    uint256 public nextId;

    IFeeManager public feeManager;

    //Trigger for ReferralManager mode
    bool public isReferralManagerEnabled;

    IReferralManager public referralManager;

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

    function _createERC20(
        uint256 _id,
        address _owner,
        bytes memory _implementationData
    ) internal returns (address) {
        require(_owner != address(0), "Owner should not be zero address");
        address implementation = implementationIdVsImplementation[_id];
        require(implementation != address(0), "Invalid implementation");

        address erc20Library = createClone(implementation);
        IMinimalProxy(erc20Library).init(_implementationData);

        OwnableUpgradeable(erc20Library).transferOwnership(_owner);
        erc20Contracts.push(erc20Library);

        emit ERC20Created(_id, erc20Library);
        return erc20Library;
    }

    function createERC20(
        uint256 _id,
        address _owner,
        bytes memory _implementationData
    ) external payable returns (address) {
        address erc20Adddress = _createERC20(_id, _owner, _implementationData);
        _handleFeeManager();
        return erc20Adddress;
    }

    function createERC20WithReferral(
        uint256 _id,
        address _owner,
        address referrer,
        bytes memory _implementationData
    ) external payable returns (address) {
        address erc20Adddress = _createERC20(_id, _owner, _implementationData);
        (uint256 feeAmount, ) = _handleFeeManager();
        _handleReferral(referrer, feeAmount);
        return erc20Adddress;
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
