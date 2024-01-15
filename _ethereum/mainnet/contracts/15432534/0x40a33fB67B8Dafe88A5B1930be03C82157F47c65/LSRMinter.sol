// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeMath.sol";

import "./IMSDController.sol";
import "./IMSD.sol";

/**
 * @title dForce's Liquid Stability Reserve Minter
 * @author dForce
 */
abstract contract LSRMinter {
    using SafeMath for uint256;

    /// @dev Address of MSD.
    address internal msd_;

    /// @dev Address of msdController.
    IMSDController internal msdController_;

    /// @dev Minter's total mint storage
    uint256 internal totalMint_;

    /**
     * @notice Initialize the MSD controller and MSD.
     * @param _msdController MSD controller address.
     * @param _msd MSD address.
     */
    function _initialize(IMSDController _msdController, address _msd)
        internal
        virtual
    {
        require(_msd != address(0), "LSRMinter: _msd cannot be zero address");
        require(
            _msdController.isMSDController(),
            "LSRMinter: _msdController is not MSD controller contract"
        );

        msd_ = _msd;
        msdController_ = _msdController;
    }

    /**
     * @dev Mint MSD to recipient.
     * @param _recipient Recipient address.
     * @param _amount Amount of minted MSD.
     */
    function _mint(address _recipient, uint256 _amount) internal virtual {
        totalMint_ = totalMint_.add(_amount);
        msdController_.mintMSD(msd_, _recipient, _amount);
    }

    /**
     * @dev Burn MSD.
     * @param _from Burned MSD holder address.
     * @param _amount Amount of MSD burned.
     */
    function _burn(address _from, uint256 _amount) internal virtual {
        totalMint_ = totalMint_.sub(_amount);
        IMSD(msd_).burn(_from, _amount);
    }

    /**
     * @dev  Msd quota provided by the minter.
     */
    function _msdQuota() internal view returns (uint256 _quota) {
        uint256 _mintCaps = msdController_.mintCaps(msd_, address(this));
        if (_mintCaps > totalMint_) _quota = _mintCaps - totalMint_;
    }

    /**
     * @dev MSD address.
     */
    function msd() external view returns (address) {
        return msd_;
    }

    /**
     * @dev MSD controller address.
     */
    function msdController() external view returns (IMSDController) {
        return msdController_;
    }

    /**
     * @dev  Minter's total mint.
     */
    function totalMint() external view returns (uint256) {
        return totalMint_;
    }

    /**
     * @dev  Minter's mint cap.
     */
    function mintCap() external view returns (uint256) {
        return msdController_.mintCaps(msd_, address(this));
    }

    /**
     * @dev  Msd quota provided by the minter.
     */
    function msdQuota() external view returns (uint256) {
        return _msdQuota();
    }
}
