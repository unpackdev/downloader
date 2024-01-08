// SPDX-License-Identifier: MIT

/*
#     #                           #                     #####                       
##   ## ###### #####   ##        # #   #####  #####    #     # #      #    # #####  
# # # # #        #    #  #      #   #  #    #   #      #       #      #    # #    # 
#  #  # #####    #   #    #    #     # #    #   #      #       #      #    # #####  
#     # #        #   ######    ####### #####    #      #       #      #    # #    # 
#     # #        #   #    #    #     # #   #    #      #     # #      #    # #    # 
#     # ######   #   #    #    #     # #    #   #       #####  ######  ####  #####  
                                                                                    

*/

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./TieredTokensWithDistributor.sol";

contract TMAC is TieredTokensWithDistributor, Ownable, ReentrancyGuard, ERC721Enumerable {
    string public provenance;
    string private _baseURIextended;
    bool public saleActive = false;

    uint256 public immutable tier0MaxAllowListMint;
    uint256 public immutable tier0MaxPublicMint;
    uint256 public immutable tier0PricePerToken;
    uint256 public immutable tier1MaxAllowListMint;
    uint256 public immutable tier1MaxPublicMint;
    uint256 public immutable tier1PricePerToken;

    uint256 public immutable maxSupply;
    address public immutable shareholderAddress;

    constructor(
        address shareholderAddress_,
        uint256[] memory tierSupply,
        uint256[] memory maxAllowListMint,
        uint256[] memory maxPublicMint,
        uint256[] memory pricePerToken
    ) ERC721("The Meta Art Club", "TMAC") TieredTokensWithDistributor(tierSupply) {
        require(shareholderAddress_ != address(0));
        require(tierSupply.length == 2, 'Invalid tier supply length');
        require(maxAllowListMint.length == 2, 'Invalid max allow list mint length');
        require(maxPublicMint.length == 2, 'Invalid max public mint length');
        require(pricePerToken.length == 2, 'Invalid price per token length');

        // set shareholder address
        shareholderAddress = shareholderAddress_;

        // calculate total supply
        uint256 supply = 0;

        for (uint256 index = 0; index < tierSupply.length; index++) {
            supply += tierSupply[index];
        }

        maxSupply = supply;

        // assign constants
        tier0MaxAllowListMint = maxAllowListMint[0];
        tier0MaxPublicMint = maxPublicMint[0];
        tier0PricePerToken = pricePerToken[0];
        tier1MaxAllowListMint = maxAllowListMint[1];
        tier1MaxPublicMint = maxPublicMint[1];
        tier1PricePerToken = pricePerToken[1];
    }

    /**
     * @dev throws when sale is not active
     */
    modifier isSaleActive() {
        require(saleActive, 'Public sale is not active');
        _;
    }

    /**
     * tokens
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance_) public onlyOwner {
        provenance = provenance_;
    }

    function setSaleActive(bool saleActive_) public onlyOwner {
        saleActive = saleActive_;
    }

    /**
     * allow list
     */
    function setAllowListActive(bool allowListActive) external onlyOwner {
        _setAllowListActive(allowListActive);
    }

    function setAllowList(bytes32 merkleRoot) external onlyOwner {
        _setAllowList(merkleRoot);
    }

    function _mintTieredToken(uint256 tierId, uint256 numberOfTokens) internal canMintInTier(tierId, numberOfTokens) {
        uint256 ts = _getTokenIndexInTier(tierId);

        _incrementTokensInTier(tierId, numberOfTokens);

        for (uint256 index = 0; index < numberOfTokens; index++) {
            _safeMint(msg.sender, ts + index);
        }
    }

    function reserve(uint256 tierId, uint256 numberOfTokens) public onlyOwner {
        _mintTieredToken(tierId, numberOfTokens);
    }

    /**
     * public
     */
    function _mintAllowList(
        uint256 tierId,
        uint256 numberOfTokens,
        uint256 tierTokenLimit,
        bytes32[] memory merkleProof
    ) internal isAllowListActive withinTierLimitForAddress(msg.sender, tierId, numberOfTokens, tierTokenLimit) {
        _claim(msg.sender, tierId, numberOfTokens, merkleProof);

        _mintTieredToken(tierId, numberOfTokens);
    }

    function mintAllowListTier0(uint256 numberOfTokens, bytes32[] memory merkleProof) external payable nonReentrant {
        require(tier0PricePerToken * numberOfTokens <= msg.value, 'Ether value sent is not correct');

        _mintAllowList(0, numberOfTokens, tier0MaxAllowListMint, merkleProof);
    }

    function mintAllowListTier1(uint256 numberOfTokens, bytes32[] memory merkleProof) external payable nonReentrant {
        require(tier1PricePerToken * numberOfTokens <= msg.value, 'Ether value sent is not correct');
        _mintAllowList(1, numberOfTokens, tier1MaxAllowListMint, merkleProof);
    }

    function mintTier0(uint256 numberOfTokens) external payable nonReentrant isSaleActive {
        require(tier0PricePerToken * numberOfTokens <= msg.value, 'Ether value sent is not correct');
        require(numberOfTokens <= tier0MaxPublicMint, 'Number of tokens exceeds limit');

        _mintTieredToken(0, numberOfTokens);
    }

    function mintTier1(uint256 numberOfTokens) external payable nonReentrant isSaleActive {
        require(tier1PricePerToken * numberOfTokens <= msg.value, 'Ether value sent is not correct');
        require(numberOfTokens <= tier1MaxPublicMint, 'Number of tokens exceeds limit');

        _mintTieredToken(1, numberOfTokens);
    }

    function numberAvailableToMint(
        uint256 tierId,
        address claimer,
        bytes32[] memory merkleProof
    ) external view returns (uint256) {
        if (onAllowList(claimer, merkleProof)) {
            if (tierId == 0) {
                return tier0MaxAllowListMint - numberMintedInTier(tierId, claimer);
            } else if (tierId == 1) {
                return tier1MaxAllowListMint - numberMintedInTier(tierId, claimer);
            }

            return 0;
        }

        return 0;
    }

    /**
     * withdraw
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(shareholderAddress).transfer(balance);
    }
}