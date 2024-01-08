// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./Governable.sol";
import "./BeaconStorage.sol";
import "./IBeacon.sol";
import "./ITreasuryConfig.sol";
import "./IMirrorTokenLogic.sol";
import "./MirrorTokenStorage.sol";

/**
 * @title MirrorGovernanceToken
 * @author MirrorXYZ
 *
 *  An ERC20 that grants access to the ENS namespace through a
 *  burn-and-register model.
 */
contract MirrorTokenLogic is
    BeaconStorage,
    Governable,
    MirrorTokenStorage,
    IMirrorTokenLogic
{
    /// @notice Logic version
    uint256 public constant override version = 0;

    // ============ Events ============

    /// @notice Mint event
    event Mint(address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(
        address indexed from,
        address indexed spender,
        uint256 value
    );

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 value);

    // ============ Modifiers ============

    modifier onlyMinter() {
        require(
            msg.sender == ITreasuryConfig(treasuryConfig).distributionModel() ||
                msg.sender == governor,
            "only active distribution model can mint"
        );
        _;
    }

    constructor(address beacon_, address owner_)
        BeaconStorage(beacon_)
        Governable(owner_)
    {}

    // ============ ERC20 Spec ============

    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        require(
            allowance[from][msg.sender] >= value,
            // value == 0 || allowance[from][msg.sender] >= value,
            "transfer amount exceeds spender allowance"
        );

        allowance[from][msg.sender] = allowance[from][msg.sender] - value;
        _transfer(from, to, value);
        return true;
    }

    // ============ Minting ============

    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external override onlyMinter {
        _mint(to, amount);

        emit Mint(to, amount);
    }

    function setTreasuryConfig(address newTreasuryConfig)
        public
        override
        onlyGovernance
    {
        treasuryConfig = newTreasuryConfig;
    }

    // ============ Upgradability Utils ============
    function getLogic() public view returns (address proxyLogic) {
        proxyLogic = IBeacon(beacon).logic();
    }

    // ============ Private Utils ============

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply + value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from] - value;
        totalSupply = totalSupply - value;
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        require(balanceOf[from] >= value, "transfer amount exceeds balance");

        balanceOf[from] = balanceOf[from] - value;
        balanceOf[to] = balanceOf[to] + value;

        emit Transfer(from, to, value);
    }
}
