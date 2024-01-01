pragma solidity 0.8.19;

import "./Ownable.sol";
import "./ERC721.sol";

import "./IERC20.sol";

contract AbstractNFT is ERC721, Ownable {
    // State variables
    address internal token;
    address internal dev;
    uint256 internal mintFee;
    uint16 internal acquisitionTaxBasisPoints;

    mapping(uint256 => uint24) internal pixelColor;

    mapping(uint256 => uint256) internal prices;

    // maps an index to a tokenId. Enables enumerating tokens.
    mapping(uint256 => uint256) internal idmap;
    uint256 internal idcount;

    constructor(
        string memory __name,
        address _token,
        address _dev,
        uint256 _mintFee,
        uint16 _acquisitionTaxBasisPoints
    ) public ERC721(__name, "PX") {
        token = _token;
        dev = _dev;
        mintFee = _mintFee;
        acquisitionTaxBasisPoints = _acquisitionTaxBasisPoints;
    }

    function getToken() public view returns (address) {
        return token;
    }

    function getDevAddress() public view returns (address) {
        return dev;
    }

    function getMintFee() public view returns (uint256) {
        return mintFee;
    }

    function getAcquisitionTaxBasisPoints() public view returns (uint16) {
        return acquisitionTaxBasisPoints;
    }

    // Changers

    function changeToken(address _newToken) public onlyOwner {
        token = _newToken;
    }

    function changeDevAddress(address _newDev) public onlyOwner {
        dev = _newDev;
    }

    function changeMintFee(uint256 _newFee) public onlyOwner {
        mintFee = _newFee;
    }

    function changeAcquisitionTaxBasisPoints(uint16 _newbp) public onlyOwner {
        acquisitionTaxBasisPoints = _newbp;
    }

    function getIdCount() public view returns (uint256) {
        return idcount;
    }

    function getTokenIdsBulk(
        uint256[] calldata indices
    ) public view returns (uint256[] memory) {
        uint256[] memory rv = new uint256[](indices.length);

        // WARN: This unbounded for loop is an anti-pattern
        for (uint i = 0; i < indices.length; i++) {
            rv[i] = idmap[indices[i]];
        }

        return rv;
    }

    function getTokenIdsRange(
        uint256 from,
        uint256 to
    ) public view returns (uint256[] memory) {
        uint256[] memory rv = new uint256[](to - from);
        uint16 k = 0;

        // WARN: This unbounded for loop is an anti-pattern
        for (uint256 i = from; i < to; i++) {
            rv[k] = idmap[i];
            k++;
        }

        return rv;
    }

    function unsafeTransferPixel(uint256 tokenId, address to) public virtual {
        // Virtual function
    }

    /**
     * Minting functions
     */
    function mintPixel(uint256 id, uint24 c) public virtual {
        // Virtual function
    }

    function mintPixelBulk(
        uint256[] calldata tokenIds,
        uint24[] calldata c
    ) public virtual {
        // Virtual function
    }

    /**
     * Getters
     */
    function getPixelColor(uint256 tokenId) public view returns (uint24) {
        return pixelColor[tokenId];
    }

    function getPixelColorBulk(
        uint256[] calldata tokenIds
    ) public view returns (uint24[] memory) {
        uint24[] memory rv = new uint24[](tokenIds.length);

        // WARN: This unbounded for loop is an anti-pattern
        for (uint i = 0; i < tokenIds.length; i++) {
            rv[i] = pixelColor[tokenIds[i]];
        }

        return rv;
    }

    function getPixelColorBulkRange(
        uint256 from,
        uint256 to
    ) public view returns (uint24[] memory) {
        uint24[] memory rv = new uint24[](to - from);
        uint16 k = 0;
        // WARN: This unbounded for loop is an anti-pattern
        for (uint256 i = from; i < to; i++) {
            rv[k] = pixelColor[idmap[i]];
            k++;
        }

        return rv;
    }

    function getTokenIdsAndPixelColorsBulkRange(
        uint256 from,
        uint256 to
    ) public view returns (uint256[] memory, uint24[] memory) {
        uint256[] memory rv_ids = new uint256[](to - from);
        uint24[] memory rv_cols = new uint24[](to - from);

        uint16 k = 0;

        // WARN: This unbounded for loop is an anti-pattern
        for (uint256 i = from; i < to; i++) {
            rv_ids[k] = idmap[i];
            rv_cols[k] = pixelColor[idmap[i]];
            k++;
        }

        return (rv_ids, rv_cols);
    }

    function getTokenIdsAndPixelColorsAndUserIndicesBulkRange(
        uint256 from,
        uint256 to,
        address user
    ) public view returns (uint256[] memory, uint24[] memory,  bool[] memory) {
        uint256[] memory rv_ids = new uint256[](to - from);
        uint24[] memory rv_cols = new uint24[](to - from);
        bool[] memory ownedByUser = new bool[](to - from);

        uint16 k = 0;

        // WARN: This unbounded for loop is an anti-pattern
        for (uint256 i = from; i < to; i++) {
            rv_ids[k] = idmap[i];
            rv_cols[k] = pixelColor[idmap[i]];

            if (_ownerOf(idmap[i]) == user) {
                ownedByUser[k] = true;
            } else {
                ownedByUser[k] = false;
            }

            // last thing to do.
            k++;
        }

        return (rv_ids, rv_cols, ownedByUser);
    }

    /**
     * Price Getters
     */
    function getPixelPrice(uint256 tokenId) public view returns (uint256) {
        return prices[tokenId];
    }

    function getPixelPriceBulk(
        uint256[] calldata tokenIds
    ) public view returns (uint256[] memory) {
        uint256[] memory rv = new uint256[](tokenIds.length);

        // WARN: This unbounded for loop is an anti-pattern
        for (uint i = 0; i < tokenIds.length; i++) {
            rv[i] = prices[tokenIds[i]];
        }

        return rv;
    }

    function getPixelPriceBulkRange(
        uint256 from,
        uint256 to
    ) public view returns (uint256[] memory) {
        uint256[] memory rv = new uint256[](to - from);
        uint16 k = 0;
        for (uint256 i = from; i < to; i++) {
            rv[k] = prices[idmap[i]];
            k++;
        }
        return rv;
    }

    /**
     * Setters
     */
    function setPixelColor(uint256 tokenId, uint24 c) public {
        require(_ownerOf(tokenId) == msg.sender);
        pixelColor[tokenId] = c;
    }

    function setPixelColorBulk(
        uint256[] calldata tokenIds,
        uint24[] calldata c
    ) public {
        require(tokenIds.length == c.length);

        // WARN: This unbounded for loop is an anti-pattern
        for (uint i = 0; i < tokenIds.length; i++) {
            require(_ownerOf(tokenIds[i]) == msg.sender);
            pixelColor[tokenIds[i]] = c[i];
        }
    }

    /**
     * Acquisition
     */
    function acquirePixel(uint256 id) public virtual {
        // Virtual function
    }

    function acquirePixelWithChange(uint256 id, uint24 c) public virtual {
        // Virtual function
    }

    function acquirePixelBulk(uint256[] calldata tokenIds) public virtual {
        // Virtual function
    }

    function acquirePixelBulkWithChange(
        uint256[] calldata tokenIds,
        uint24[] calldata c
    ) public virtual {
        // Virtual function
    }

    /*
     * Full committers
     */
    function commit(
        uint256 tokenId,
        uint24 c,
        uint256 newPrice
    ) public virtual {
        // TODO: Implement in derived contract
    }

    /*
     * Full committers
     */
    function commitBulk(
        uint256[] calldata tokenIds,
        uint24[] calldata cs,
        uint256[] calldata newPrices
    ) public virtual {
        // TODO: Implement in derived contract
    }

    function getCommitFeeTaxPriceAndCounts(
        uint256 tokenId,
        uint256 newPrice,
        address beneficiary
    ) public view virtual returns (uint256[3] memory, uint16[2] memory) {
        // Returns: [fee, tax, total price], [mint count, overwrite count]
        // Fee + Tax + Price should be equal to the amount paid by the committer.
        // Fee + Tax is received by devs, and price is received by pixel owners.
        // TODO: Implement in derived contract
    }

    function getCommitBulkFeeTaxPriceAndCounts(
        uint256[] calldata tokenIds,
        uint256[] calldata newPrices,
        address beneficiary
    ) public view virtual returns (uint256[3] memory, uint16[2] memory) {
        // Returns: fee, tax, total price, mint count, overwrite count
        // Fee + Tax + Price should be equal to the amount paid by the committer.
        // Fee + Tax is received by devs, and price is received by pixel owners.
        // TODO: Implement in derived contract
    }

    /*
     * Full committers
     */
    function commitForBeneficiary(
        uint256 tokenId,
        uint24 c,
        uint256 newPrice,
        address beneficiary
    ) public virtual {
        // TODO: Implement in derived contract
    }

    /*
     * Full committers
     */
    function commitBulkForBeneficiary(
        uint256[] calldata tokenIds,
        uint24[] calldata cs,
        uint256[] calldata newPrices,
        address beneficiary
    ) public virtual {
        // TODO: Implement in derived contract
    }
}
