// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC20.sol";
import "./ERC20Pausable.sol";
import "./AccessControl.sol";

import "./IOFT.sol";
import "./OFTCore.sol";

contract Stablecomp is OFTCore, ERC20, ERC20Pausable, AccessControl, IOFT {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    address public immutable lzEndpointAddress;

    /// @dev The hard cap for token creation: 200 million tokens.
    uint256 public constant maxSupply = 200_000_000 * 10 ** 18;

    constructor(
        address admin,
        address _lzEndpointAddress
    ) ERC20("Stablecomp", "SCOMP") OFTCore(_lzEndpointAddress) {
        lzEndpointAddress = _lzEndpointAddress;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);

        if (block.chainid == 1) {
            _mint(msg.sender, maxSupply);
        }
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(OFTCore, AccessControl, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IOFT).interfaceId ||
            interfaceId == type(IERC20).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function token() external view virtual override returns (address) {
        return address(this);
    }

    function circulatingSupply() external view virtual override returns (uint) {
        return totalSupply();
    }

    function _debitFrom(
        address _from,
        uint16,
        bytes memory,
        uint _amount
    ) internal virtual override returns (uint) {
        address spender = _msgSender();
        if (_from != spender) _spendAllowance(_from, spender, _amount);
        _burn(_from, _amount);
        return _amount;
    }

    function _creditTo(
        uint16,
        address _toAddress,
        uint _amount
    ) internal virtual override returns (uint) {
        _mint(_toAddress, _amount);
        return _amount;
    }

    /* ------- The following functions are overrides required by Solidity. ------ */

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
