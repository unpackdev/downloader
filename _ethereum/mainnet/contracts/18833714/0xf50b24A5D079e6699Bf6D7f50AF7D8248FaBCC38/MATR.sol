//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.19;

import "./ERC20Burnable.sol";
import "./Ownable.sol";

/**
 * @title MATR token
 * @author Swarm
 */
contract MATR is ERC20, ERC20Burnable, Ownable {
    /**
     * KnowYourAsset
     */
    string public KYA;

    /**
     * MATR constructor.
     */
    constructor() ERC20("MATR", "MATR") {
        _mint(msg.sender, 180000000 * 10 ** 18);
    }

    /**
     * Sets KYA.
     */
    function setKYA(string calldata _knowYourAsset) external onlyOwner {
        KYA = _knowYourAsset;
    }
}
