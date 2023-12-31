// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title EsToken is an ERC20-compliant token, but cannot be transferred and can only be minted through the esTokenMinter contract or redeemed for Token by destruction.
 * - The maximum amount that can be minted through the esTokenMinter contract is 55 million.
 * - EsToken can be used for community governance voting.
 */
import "./OwnableUpgradeable.sol";
import "./ERC20VotesUpgradeable.sol";

import "./IDividends.sol";

contract EsToken is OwnableUpgradeable, ERC20VotesUpgradeable {
    uint256 public constant MAX_MINTED = 1_000_000 * 1e18;

    address public dividends;
    address public vester;
    uint256 public totalMinted;
    mapping(address => bool) public esTokenMinter;

    event DividendsChanged(address indexed dividends);
    event VesterChanged(address indexed vester);

    function initialize() public initializer {
        __Ownable_init();
        __ERC20Votes_init();
        __ERC20Permit_init("xMORI");
        __ERC20_init("xMORI", "xMORI");
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        revert("not authorized");
    }

    function setDividends(address _dividends) external onlyOwner {
        dividends = _dividends;
        emit DividendsChanged(dividends);
    }

    function setVester(address _vester) external onlyOwner {
        vester = _vester;
        emit VesterChanged(vester);
    }

    function setMinter(address[] calldata _contracts, bool[] calldata _bools) external onlyOwner {
        require(_contracts.length == _bools.length, "invalid length");

        for (uint256 i = 0; i < _contracts.length; i++) {
            esTokenMinter[_contracts[i]] = _bools[i];
        }
    }

    function mint(address user, uint256 amount) external returns (bool) {
        require(msg.sender == vester || esTokenMinter[msg.sender] == true, "not authorized");
        uint256 reward = amount;
        if (msg.sender != vester) {
            if (totalMinted + reward > MAX_MINTED) {
                reward = MAX_MINTED - totalMinted;
            }
            totalMinted += reward;
        }

        _mint(user, reward);

        if (dividends != address(0)) {
            IDividends(dividends).allocate(user, reward);
        }

        return true;
    }

    function burn(address user, uint256 amount) external returns (bool) {
        require(msg.sender == vester || esTokenMinter[msg.sender] == true, "not authorized");
        _burn(user, amount);

        if (dividends != address(0)) {
            IDividends(dividends).deallocate(user, amount);
        }

        return true;
    }
}
