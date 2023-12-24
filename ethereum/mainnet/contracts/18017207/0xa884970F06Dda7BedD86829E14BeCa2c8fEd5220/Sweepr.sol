// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./OFT.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20Votes.sol";
import "./ITransferApprover.sol";

contract SweeprCoin is OFT, ERC20Burnable, ERC20Permit, ERC20Votes {
    ITransferApprover private transferApprover;

    bool public isGovernanceChain;
    uint256 private _totalMinted;
    // Destination Chain Ids
    uint16[] public chainIds; 
    // Map chain Id to Sweep address
    mapping(uint16 => address) public chains;

    /// @notice SWEEPR price. This is in SWEEP
    uint256 public price = 1e6; // 1 SWEEP
    uint256 public constant MAX_SUPPLY = 10000000e18; // 10M SWEEPR
    uint256 private constant PRECISION = 1e6;

    /* ========== EVENTS ========== */
    event TokenMinted(address indexed to, uint256 amount);
    event TokenBurned(address indexed to, uint256 amount);
    event SweeprPriceSet(uint256 price);
    event ApproverSet(address indexed approver);
    event GovernanceChainSet(bool isGovernance);
    event ChainAdded(uint16 dstChainId, address indexed balancer);
    event ChainRemoved(uint16 dstChainId);

    /* ========== Errors ========== */
    error TransferNotAllowed();
    error ZeroAddressDetected();
    error OverMaxSupply();
    error NotGovernanceChain();

    /* ========== CONSTRUCTOR ========== */
    constructor(
        bool isGovernance,
        address lzEndpoint
    ) OFT("SweeprCoin", "SWEEPR", lzEndpoint) ERC20Permit("SweeprCoin") {
        isGovernanceChain = isGovernance;
    }

    /* ========== VIEW FUNCTIONS ========== */
    function chainCount() external view returns (uint256) {
        return chainIds.length;
    }

    function getChainId(uint256 index) external view returns (uint16) {
        return chainIds[index];
    }

    function getBalancerWithChainId(uint16 chainId) external view returns (address) {
        return chains[chainId];
    }

    /* ========== RESTRICTED FUNCTIONS ========== */
    function mint(address receiver, uint256 amount) external onlyOwner {
        if (!isGovernanceChain) revert NotGovernanceChain();
        if (totalSupply() + amount > MAX_SUPPLY) revert OverMaxSupply();
        
        _mint(receiver, amount);
        _totalMinted += amount;

        emit TokenMinted(receiver, amount);
    }

    function setGovernanceChain(bool isGovernance) external onlyOwner {
        isGovernanceChain = isGovernance;

        emit GovernanceChainSet(isGovernance);
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;

        emit SweeprPriceSet(newPrice);
    }

    function setTransferApprover(address newApprover) external onlyOwner {
        if (newApprover == address(0)) revert ZeroAddressDetected();
        transferApprover = ITransferApprover(newApprover);

        emit ApproverSet(newApprover);
    }

    /**
     * @notice Add Destination Chain
     * @param dstChainId Destination Chain Id.
     * @param balancer address of balancer in destination chain.
     */
    function addChain(uint16 dstChainId, address balancer) external onlyOwner {
        chainIds.push(dstChainId);
        chains[dstChainId] = balancer;

        emit ChainAdded(dstChainId, balancer);
    }

    /**
     * @notice Remove Destination Chain Id
     * @param itemIndex index to remove.
     */
    function removeChain(uint256 itemIndex) external onlyOwner {
        uint16 removedChainId = chainIds[itemIndex];
        delete chains[removedChainId];

        chainIds[itemIndex] = chainIds[chainIds.length -1];
        chainIds.pop();

        emit ChainRemoved(removedChainId);
    }

    function burn(uint256 amount) public override {
        if (!isGovernanceChain) revert NotGovernanceChain();
        super.burn(amount);

        _totalMinted -= amount;

        emit TokenBurned(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) public override {
        if (!isGovernanceChain) revert NotGovernanceChain();
        super.burnFrom(account, amount);

        _totalMinted -= amount;

        emit TokenBurned(account, amount);
    }

    function totalMinted() external view returns(uint256) {
        return _totalMinted;
    }

    /* ========== OVERRIDDEN FUNCTIONS ========== */
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        if (
            address(transferApprover) != address(0) &&
            !transferApprover.checkTransfer(from, to, amount)
        ) revert TransferNotAllowed();

        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}