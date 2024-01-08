pragma solidity ^0.4.24;

import "./ERC20.sol";
import "./ERC20Pausable.sol";
import "./Ownable.sol";
import "./ERC20PreMint.sol";

/**
 * @title Get the balance of an ERC20 contract to mint tokens for a pre-mintable ERC20 contract
 **/
contract BalanceCopier is Ownable {
    ERC20Pausable public oldToken;
    ERC20PreMint public newToken;

    mapping (address => bool) internal copied;
    mapping (address => bool) public excluded;

    constructor(ERC20Pausable _oldToken, ERC20PreMint _newToken, address[] _exclude) public {
        oldToken = _oldToken;
        newToken = _newToken;

        excluded[address(_oldToken)] = true;

        for (uint i=0; i < _exclude.length; i++) {
            excluded[_exclude[i]] = true;
        }
    }

    modifier whenBothPaused() {
        require(oldToken.paused(), "Old ERC20 contract is not paused");
        require(!newToken.minted(), "New ERC20 token is already pre-minted");
        _;
    }

    function copy(address _holder) external whenBothPaused {
        require(!excluded[_holder], 'Address is excluded');
        require(!copied[_holder], 'Already copied balance of this holder');

        uint256 balance = oldToken.balanceOf(_holder);
        require(balance > 0, 'Zero balance');

        _mint(_holder, balance);
    }

    function copyAll(address[] _holders) external whenBothPaused {
        uint length = _holders.length;

        for (uint i=0; i < length; i++) if (!copied[_holders[i]] && !excluded[_holders[i]]) {
            address holder = _holders[i];
            uint256 balance = oldToken.balanceOf(holder);

            if (balance != 0) {
                _mint(holder, balance);
            }
        }
    }

    function done() external onlyOwner {
        newToken.unpause();
        newToken.renouncePauser();
    }

    function _mint(address _holder, uint256 _balance) internal {
        newToken.mint(_holder, _balance);
        copied[_holder] = true;
    }
}
