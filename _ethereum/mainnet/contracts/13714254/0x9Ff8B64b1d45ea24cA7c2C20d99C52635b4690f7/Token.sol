// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard.
 * with only balanceOf method available
 */
interface ERC721 {
    function balanceOf(address _owner) external view returns (uint256);
}

/**
 * @title $TROPHY Token (The native ecosystem token of Monster Shelter)
 * @dev Extends standard ERC20 contract from OpenZeppelin
 */
contract MonsterTrophy is ERC20, Ownable {

    // a mapping from an address to whether or not it can mint / burn
    mapping(address => bool) controllers;

    /// @notice $TROPHY tokens claimable per day for each MNSTRS NFT holder
    uint256 public EMISSION_PER_DAY = 50e18;

    /// @notice Start timestamp for emissions
    uint256 public immutable emissionStart = 1638208800;

    /// @notice End date for $TROPHY emissions to MNSTRS NFT holders
    uint256 public emissionEnd = 1639591200;

    /// @notice Cap at 10 000 000 $TROPHY
    uint256 public immutable _cap = 10000000000000000000000000;

    /// @dev A record of last claimed timestamp for MNSTRS NFTs
    mapping(address => uint256) private _lastClaim;

    /// @dev Contract address for MNSTRS NFT
    address public immutable _nftAddress = 0x79E0F1936B3F15A9E8Dd514A3EC01034C0D9fCC6;

    constructor() ERC20("Monster Trophy", "TROPHY") { }

    /**
        * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @notice Set end of emission
     * @param _newEmissionEnd Timestamp for ending the emission
     */
    function setEmissionEnd(uint256 _newEmissionEnd) external onlyOwner{
        emissionEnd = _newEmissionEnd;
    }
    /**
     * @notice Check accumulated $TROPHY tokens
     * @return Total $TROPHY accumulated and ready to claim
     */
    function accumulated() public view returns (uint256) {
        require(block.timestamp > emissionStart, "Emission has not started yet");
        uint256 balance = ERC721(_nftAddress).balanceOf(msg.sender);
        require(balance > 0, "Sender is not an owner");
        uint256 lastClaimed = uint256(_lastClaim[msg.sender]) != 0 ? uint256(_lastClaim[msg.sender]) : emissionStart;

        if (lastClaimed >= emissionEnd) return 0;

        uint256 accumulationPeriod = block.timestamp < emissionEnd ? block.timestamp : emissionEnd;
        uint256 totalAccumulated = ((accumulationPeriod - lastClaimed) * EMISSION_PER_DAY * balance) / 1 days;

        return totalAccumulated;
    }

    /**
     * @notice Mint and claim available $TROPHY
     * @return Total $TROPHY claimed
     */
    function claim() public returns (uint256) {
        require(block.timestamp > emissionStart, "Emission has not started yet");

        uint256 totalClaimQty = accumulated();

        require(totalClaimQty != 0, "No accumulated TROPHY");
        _mint(_msgSender(), totalClaimQty);
        _lastClaim[msg.sender] = block.timestamp;
        return totalClaimQty;
    }
    /**
   * mints $TROPHY to a recipient
   * @param to The recipient of the $TROPHY
   * @param amount The amount of $TROPHY to mint
   */
    function mint(address to, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can mint");
        _mint(to, amount);
    }

    /**
   * burns $TROPHY from a holder
   * @param from The holder of the $TROPHY
   * @param amount The amount of $TROPHY to burn
   */
    function burn(address from, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can burn");
        _burn(from, amount);
    }
    /**
   * enables an address to mintOnHunt / burnOnHunt
   * @param controller The address to enable
   */
    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }
    /**
   * disables an address from mintOnHunt / burnOnHunt
   * @param controller The address to disable
   */
    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }
}
