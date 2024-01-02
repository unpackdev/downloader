// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
    ERC1155-C Smart Contract
*/

import "./ERC1155C.sol";
import "./MerkleProof.sol";
import "./Pausable.sol";
import "./Counters.sol";
import "./ERC1155Supply.sol";
import "./AccessControl.sol";
import "./IERC20.sol";
import "./IERC2981.sol";
import "./ReentrancyGuard.sol";

/// @custom:security-contact andreas.gaufer@safectory.com
contract ERC1155NFT is AccessControl, Pausable, ERC1155C, ERC1155Supply, IERC2981, ReentrancyGuard {

    using Counters for Counters.Counter;

    uint256 public price = 1200e6; // The initial price to mint in WEI.
    uint256 public discount = 0;
    // Default commission percentage
    uint256 public defaultCommissionPercentage = 10;

    mapping(uint256 => uint256) public tokenMaxSupply; // 0 is openEnd
    mapping(uint256 => uint256) public perWalletMaxTokens; // 0 is openEnd

    bytes32 public merkleRoot;
    address public discountContract = 0x0000000000000000000000000000000000000000;
    bytes4 public discountOwnerFunctionSelector = bytes4(keccak256("ownerOf(uint256)"));
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");
    bytes32 public constant SALES_ROLE = keccak256("SALES_ROLE");

    IERC20 public usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    // Add this at the top of your contract
    enum SalesMode {ETH, USDC}
    mapping(uint256 => SalesMode) public salesMode;

    uint256[] public saleIsActive;

    struct SaleSchedule {
        uint256 start;
        uint256 end;
    }
    // Struct to hold keyword data
    struct KeywordData {
        address payoutAddress;
        uint256 commissionPercentage;
    }
    // Define a new struct type to hold the commission and payout address
    struct CommissionData {
        uint256 commission;
        address payoutAddress;
    }

    struct RoyaltyData {
        address payable recipient;
        uint256 percentageBasisPoints;
    }

    mapping(uint256 => RoyaltyData) public _tokenRoyalties;

    // Mapping from keyword hash to data
    mapping(bytes32 => KeywordData) public keywordAffiliates;
    mapping(uint256 => SaleSchedule) private saleSchedules;
    // Mapping from payout address to balance
    mapping(address => uint256) public affiliateBalancesETH;
    mapping(address => uint256) public affiliateBalancesUSDC;

    // Variables to store the total affiliate balances
    uint256 public totalAffiliateBalanceETH;
    uint256 public totalAffiliateBalanceUSDC;

    mapping(uint256 => bool) public saleMaxLock;
    bool public allowContractMints = false;
    bool[] private discountUsed;

    Counters.Counter public reservedSupply;

    string private _contractURI;
    constructor(string memory uri_) ERC1155OpenZeppelin(uri_) payable
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(SALES_ROLE, msg.sender);
    }

    function setRoyalty(uint256 tokenId, address payable recipient, uint256 percentageBasisPoints) external onlyRole(ADMIN_ROLE) {
        require(percentageBasisPoints <= 10000, "Percentage too high"); // max 100%

        _tokenRoyalties[tokenId] = RoyaltyData({
            recipient: recipient,
            percentageBasisPoints: percentageBasisPoints
        });
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address, uint256) {
        RoyaltyData memory royaltyData = _tokenRoyalties[tokenId];
        return (royaltyData.recipient, salePrice * royaltyData.percentageBasisPoints / 10000);
    }

    function setUsdcAddress(address newUsdc) public onlyRole(ADMIN_ROLE) {
        usdc = IERC20(newUsdc);
    }

    function setSalesMode(uint256 tokenId, SalesMode mode) public onlyRole(SALES_ROLE) {
        // Add necessary access control here (onlyOwner, onlyAdmin, etc.)
        salesMode[tokenId] = mode;
    }


    function setURI(string memory newuri) public onlyRole(ADMIN_ROLE) {
        _setURI(newuri);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `ADMIN_ROLE`.
     */
    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `ADMIN_ROLE`.
     */
    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function _mintCommon(address to, uint256 id, uint256 amount, uint256 discountTokenId, bytes32[] calldata proof, bytes memory data) internal view {
        // Create fixed-size memory arrays
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);

        // Assign values
        ids[0] = id;
        amounts[0] = amount;

        require(discountTokenId <= discountUsed.length, "Bad discount");
        // Call _mintBatchCommon with the created arrays
        _mintBatchCommon(to, ids, amounts, proof, data);
    }

    function _mintBatchCommon(address to, uint256[] memory ids, uint256[] memory amounts, bytes32[] calldata proof, bytes memory /* data */) internal view returns (uint256) {
        require(msg.sender == tx.origin || allowContractMints, "No contracts!");
        require((merkleRoot == 0 || _verify(_leaf(msg.sender), proof)|| _verify(_leaf(to), proof)), "Invalid proof");
        uint256 idsLen = ids.length;
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < idsLen; ++i) {
            require(ids[i] > 0, "Invalid ID");
            require(checkSaleState(ids[i]), "No sale");
            require(_checkSaleSchedule(saleSchedules[ids[i]]), "Wrong time");
            require(tokenMaxSupply[ids[i]] == 0 || totalSupply(ids[i]) + amounts[i] <= tokenMaxSupply[ids[i]], "Supply exhausted");
            require(perWalletMaxTokens[ids[i]] == 0 || balanceOf(to,ids[i]) + amounts[i] <= perWalletMaxTokens[ids[i]], "Reached per-wallet limit!");
            totalAmount = totalAmount + amounts[i];
        }
        return totalAmount;
    }

    function mintUSDC(address to, uint256 id, uint256 amount, uint256 discountTokenId, string memory keyword, bytes32[] calldata proof, bytes memory data) public nonReentrant {
        require(salesMode[id] == SalesMode.USDC, "Mode");
        _mintCommon(to, id, amount, discountTokenId, proof, data);
        uint256 priceUSDC = amount * price;
        if (discountTokenId != 0 ) {
            priceUSDC = amount * (price - discount);
            require(_checkPrice(priceUSDC, amount, discountTokenId));
        }
        // Check if the sender has enough USDC
        require(usdc.balanceOf(msg.sender) >= priceUSDC, "No USDC");

        // Calculate and update the affiliate commission
        CommissionData memory commissionData = _calculateCommission(keyword, priceUSDC, amount);
        affiliateBalancesUSDC[commissionData.payoutAddress] += commissionData.commission;
        totalAffiliateBalanceUSDC += commissionData.commission;
        super._mint(to, id, amount, data);
        // Transfer the USDC from sender to this contract
        usdc.transferFrom(msg.sender, address(this), priceUSDC);
    }

    function mint(address to, uint256 id, uint256 amount, uint256 discountTokenId, string memory keyword, bytes32[] calldata proof, bytes memory data)
    public
    payable
    {
        require(salesMode[id] == SalesMode.ETH, "mode");
        _mintCommon(to, id, amount, discountTokenId, proof, data);
        require(_checkPrice(msg.value, amount, discountTokenId), "Price");

        // Calculate and update the affiliate commission
        CommissionData memory commissionData = _calculateCommission(keyword, price, amount);
        affiliateBalancesETH[commissionData.payoutAddress] += commissionData.commission;
        totalAffiliateBalanceETH += commissionData.commission;

        // Mint the NFT
        super._mint(to, id, amount, data);
    }

    function _calculateCommission(string memory keyword, uint256 mintPrice, uint256 amount) private view returns (CommissionData memory) {
        if (bytes(keyword).length > 0 && !(bytes(keyword).length == 1 && bytes(keyword)[0] == 0x20)) {
            bytes32 keyHash = hashKeyword(keyword);

            // Get the affiliate's payout address
            address payoutAddress = keywordAffiliates[keyHash].payoutAddress;

            // Revert if a non-existent keyword is used and the keyword is not empty
            require(payoutAddress != address(0), "Keyword does not exist");

            // Calculate the affiliate commission
            uint256 commission = (getCommissionPercentage(keyHash) * mintPrice * amount) / 100;

            // Return the commission and payout address
            return CommissionData(commission, payoutAddress);
        }

        // If the keyword is empty, return a struct with zero commission and the zero address
        return CommissionData(0, address(0));
    }

    function hashKeyword(string memory keyword) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(keyword));
    }

    function setSaleActive(uint256[] memory ids, uint256[] memory tokenMaxSupplys, SalesMode[] memory modes, bool _globalLockAfterUpdate) external onlyRole(SALES_ROLE){
        require(ids.length == tokenMaxSupplys.length && ids.length == modes.length, "Array lengths must match");
        saleIsActive = ids;
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 tokenId = ids[i];
            uint256 limit = tokenMaxSupplys[i];
            require(!saleMaxLock[tokenId] || tokenMaxSupply[tokenId] == limit, "saleMaxLock");
            tokenMaxSupply[tokenId] = limit;
            salesMode[tokenId] = modes[i];
            if (!saleMaxLock[tokenId] && _globalLockAfterUpdate) {
                saleMaxLock[tokenId] = _globalLockAfterUpdate;
            }
        }

    }

    function setSaleSchedule(uint256 _id, uint256 _start, uint256 _end) external onlyRole(SALES_ROLE){
        require(_id > 0, "Invalid token type ID");
        saleSchedules[_id].start = _start;
        saleSchedules[_id].end = _end;
    }


    function flipAllowContractMintsState() external onlyRole(ADMIN_ROLE){
        allowContractMints = !allowContractMints;
    }

    function mintReservedTokens(address to, uint256 id, uint256 amount, bytes memory data) external onlyRole(ADMIN_ROLE){
        require(id > 0, "Invalid token type ID");
        require(amount == 1 || hasRole(ADMIN_ROLE, _msgSender()), "> 1 only ADMIN_ROLE");
        require(tokenMaxSupply[id] == 0 || totalSupply(id) + amount <= tokenMaxSupply[id], "Supply exhausted");
        super._mint(to, id, amount, data);
        for (uint i = 0; i < amount; i++)
        {
            reservedSupply.increment();
        }
    }

    function withdraw() external onlyRole(WITHDRAW_ROLE) nonReentrant{
        // Keep totalAffiliateBalanceETH for the Affiliates
        payable(msg.sender).transfer(address(this).balance - totalAffiliateBalanceETH);
    }

    function withdrawUSDC() external onlyRole(WITHDRAW_ROLE) nonReentrant {
        uint256 amount = usdc.balanceOf(address(this)) - totalAffiliateBalanceUSDC;
        require(amount > 0, "No USDC");
        usdc.transfer(msg.sender, amount);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes32[] calldata proof, bytes memory data)
    public
    payable
    {
        uint256 totalAmount = _mintBatchCommon(to, ids, amounts, proof, data);
        for (uint256 i = 0; i < ids.length; ++i) {
            require(salesMode[ids[i]] == SalesMode.ETH, "Mode");
        }
        require(_checkPrice(msg.value,totalAmount,0), "Price");
        super._mintBatch(to, ids, amounts, data);
    }

    function mintBatchUSDC(address to, uint256[] memory ids, uint256[] memory amounts, bytes32[] calldata proof, bytes memory data) public nonReentrant {
        uint256 totalAmount = _mintBatchCommon(to, ids, amounts, proof, data);
        for (uint256 i = 0; i < ids.length; ++i) {
            require(salesMode[ids[i]] == SalesMode.USDC, "Mode");
        }
        uint256 priceUSDC = totalAmount * price; // Calculate the price in USDC
        require(usdc.balanceOf(msg.sender) >= priceUSDC, "Price");
        usdc.transferFrom(msg.sender, address(this), priceUSDC);
        super._mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    internal
    whenNotPaused
    override(ERC1155C, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.
    bytes4 private constant _INTERFACE_ID_EIP2981 = 0x2a55205a;

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155, ERC1155C, AccessControl, IERC165)
    returns (bool)
    {
        return
            interfaceId == _INTERFACE_ID_EIP2981 ||
            super.supportsInterface(interfaceId);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyRole(ADMIN_ROLE){
        merkleRoot = _merkleRoot;
    }

    function setSaleMax(uint256 _id, uint32 _limit, bool _globalLockAfterUpdate) external onlyRole(SALES_ROLE){
        require(saleMaxLock[_id] == false , "saleMaxLock");
        require(_id > 0, "_id < 1");
        saleMaxLock[_id] = _globalLockAfterUpdate;
        tokenMaxSupply[_id] = _limit;
    }

    function setPrice(uint256 _price) external onlyRole(SALES_ROLE){
        price = _price;
    }

    function setWalletMax(uint256 _id, uint256 _walletLimit) external onlyRole(SALES_ROLE){
        require(_id > 0, "Invalid token type ID");
        perWalletMaxTokens[_id] = _walletLimit;
    }

    function setDiscountOwnerFunctionSelector(bytes4 _discountOwnerFunctionSelector) external onlyRole(SALES_ROLE){
        discountOwnerFunctionSelector = _discountOwnerFunctionSelector;
    }

    function setContractURI(string memory _uri) external onlyRole(ADMIN_ROLE) {
        _contractURI = _uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function _leaf(address account)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function _checkSaleSchedule(SaleSchedule memory s)
    internal view returns (bool)
    {
        if (
            (s.start == 0 || s.start <= block.timestamp)
            &&
            (s.end == 0 ||s.end >= block.timestamp)
        )
        {
            return true;
        }
        return false;
    }


    function _checkPrice(uint256 value, uint256 amount, uint256 discountTokenId)
    internal returns (bool)
    {
        if (value >= price * amount) {
            return true;
        } else if (discountTokenId > 0 && discountTokenId <= discountUsed.length && amount == 1 && _walletHoldsUnusedDiscountToken(msg.sender, discountContract, discountTokenId)) {
            uint256 discountedPrice = price - discount; // discount in wei
            if (value >= discountedPrice) {
                discountUsed[discountTokenId - 1] = true;
                return true;
            }
        }
        return false;
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 32))
        }
    }

    function _walletHoldsUnusedDiscountToken(address _wallet, address _contract, uint256 discountTokenId) internal returns (bool) {
        require(discountTokenId <= discountUsed.length || discountUsed[discountTokenId - 1] == false, "invalid discountTokenId");
        (bool success, bytes memory owner) = _contract.call(abi.encodeWithSelector(discountOwnerFunctionSelector, discountTokenId));
        require (success, "ownerOf fail");
        require (bytesToAddress(owner) == _wallet, "discountToken: wrong owner");
        return true;
    }

    function setDiscountContract(address _discountContract, uint256 _maxTokenId, uint256 _discount) external onlyRole(ADMIN_ROLE) {
        if (discountContract != _discountContract) {
            // reset all tokenId states to false
            discountUsed = new bool[](_maxTokenId);
        }
        discountContract = _discountContract;
        discount = _discount;
    }

    function checkSaleState(uint256 _id) internal view returns (bool){
        for (uint256 i=0; i<saleIsActive.length; i++) {
            if (saleIsActive[i] == _id) {
                return true;
            }
        }
        return false;
    }

    function registerKeyword(string memory keyword, address payoutAddress, bool replace) public onlyRole(ADMIN_ROLE) {
        // Calculate the hash of the keyword
        bytes32 keywordHash = keccak256(abi.encodePacked(keyword));

        // Check if the keyword has already been registered
        require(keywordAffiliates[keywordHash].payoutAddress == address(0) || replace, "Keyword taken");

        // Register the keyword with the payout address and default commission percentage
        if (payoutAddress == address(0)) {
            delete keywordAffiliates[keywordHash];
        } else {
            keywordAffiliates[keywordHash] = KeywordData(payoutAddress, 0);
        }
    }

    function setCommissionPercentage(string memory keyword, uint256 percentage) public onlyRole(SALES_ROLE) {
        require(percentage <= 100, ">100%");
        bytes32 keywordHash = keccak256(abi.encodePacked(keyword));
        keywordAffiliates[keywordHash].commissionPercentage = percentage;
    }

    function getCommissionPercentage(bytes32 keywordHash) public view returns (uint256) {
        uint256 percentage = keywordAffiliates[keywordHash].commissionPercentage;
        if (percentage == 0) {
            return defaultCommissionPercentage;
        } else {
            return percentage;
        }
    }

    function release(address affiliate, SalesMode mode) public nonReentrant {
        uint256 balance;
        if (mode == SalesMode.ETH) {
            balance = affiliateBalancesETH[affiliate];
            require(balance > 0, "No ETH");

            // Deducting individual affiliate balance
            affiliateBalancesETH[affiliate] = 0;

            // Deducting from total affiliate balance for ETH
            totalAffiliateBalanceETH -= balance;

            payable(affiliate).transfer(balance);
        } else if (mode == SalesMode.USDC) {
            balance = affiliateBalancesUSDC[affiliate];
            require(balance > 0, "No USDC");

            // Deducting individual affiliate balance
            affiliateBalancesUSDC[affiliate] = 0;

            // Deducting from total affiliate balance for USDC
            totalAffiliateBalanceUSDC -= balance;

            usdc.transfer(affiliate, balance);
        }
    }


    /// @dev Ties the open-zeppelin _afterTokenTransfer hook to more granular transfer validation logic
    function _afterTokenTransfer(
        address /*operator*/,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory /*amounts*/,
        bytes memory /*data*/
    ) internal virtual override (ERC1155C, ERC1155) {
        uint256 idsArrayLength = ids.length;
        for (uint256 i = 0; i < idsArrayLength;) {
            _validateAfterTransfer(from, to, ids[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _requireCallerIsContractOwner() internal view override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "not the owner");
    }
}
