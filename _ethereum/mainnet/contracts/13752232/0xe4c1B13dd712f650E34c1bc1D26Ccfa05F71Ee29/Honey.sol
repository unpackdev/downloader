// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;
import "./ERC20.sol";
import "./Ownable.sol";
import "./IHoney.sol";

contract Honey is IHoney, ERC20, Ownable {
    // a mapping of addresses allowedto mint / burn
    mapping(address => bool) controllers;

    // max amount of $HONEY for initial giveaway
    uint256 public constant GIVEAWAY_MAX = 6000000 ether;

    // how much of giveaway $HONEY was minted
    uint256 public giveawayMinted;

    constructor() ERC20("HONEY", "HONEY") {}

    /**
     * mints $HONEY to a recipient
     * @param to the recipient of $HONEY
     * @param amount the amount of $HONEY to mint
     */
    function mint(address to, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can mint");
        _mint(to, amount);
    }

    /**
     * mints Giveaway $HONEY to a array of addresses
     * @param addresses the recipients of $HONEY
     * @param amount the amount of $HONEY to mint per address
     * Cannot mint more than GIVEAWAY_MAX
     */
    function mintGiveaway(address[] calldata addresses, uint256 amount) external onlyOwner {
        uint256 arrLength = addresses.length;
        for (uint256 i = 0; i < arrLength; i++) {
            if (addresses[i] == address(0)) {
                continue;
            }
            if (giveawayMinted + amount > GIVEAWAY_MAX) {
                break;
            }
            giveawayMinted += amount;
            _mint(addresses[i], amount);
        }
    }

    /**
     * burns $HONEY from a holder
     * @param from the holder of the $HONEY
     * @param amount the amount of $HONEY to burn
     */
    function burn(address from, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can burn");
        _burn(from, amount);
    }

    /**
     * disables $honey giveaway
     */
    function disableGiveaway() external onlyOwner {
        giveawayMinted = GIVEAWAY_MAX;
    }

    /**
     * enables an address to mint / burn
     * @param controller the address to enable
     */
    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    /**
     * disables an address from minting / burning
     * @param controller the address to disbale
     */
    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }
}
