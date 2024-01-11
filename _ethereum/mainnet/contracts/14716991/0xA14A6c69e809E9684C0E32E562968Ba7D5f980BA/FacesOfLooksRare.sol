// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Ownable.sol";
import "./ERC2981.sol";
import "./ERC721.sol";

/**
 * @title Faces of LooksRare
 * @notice
LOOKSRARELOOKSRARELOOKSRLOOKSRARELOOKSRARELOOKSRARELOOKSRARELOOKSRLOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSRAR'''''''''''''''''''''''''''''''''''OOKSRLOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKS:.                                        .;OOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOO,.                                            .,KSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRAREL'                ..',;:LOOKS::;,'..                'RARELOOKSRARELOOKSR
LOOKSRARELOOKSRAR.              .,:LOOKSRARELOOKSRARELO:,.              .RELOOKSRARELOOKSR
LOOKSRARELOOKS:.             .;RARELOOKSRARELOOKSRARELOOKSl;.             .:OOKSRARELOOKSR
LOOKSRARELOO;.            .'OKSRARELOOKSRARELOOKSRARELOOKSRARE'.            .;KSRARELOOKSR
LOOKSRAREL,.            .,LOOKSRARELOOK:;;:"""":;;;lELOOKSRARELO,.            .,RARELOOKSR
LOOKSRAR.             .;okLOOKSRAREx:.              .;OOKSRARELOOK;.             .RELOOKSR
LOOKS:.             .:dOOOLOOKSRARE'      .''''..     .OKSRARELOOKSR:.             .LOOKSR
LOx;.             .cKSRARELOOKSRAR'     'LOOKSRAR'     .KSRARELOOKSRARc..            .OKSR
L;.             .cxOKSRARELOOKSRAR.    .LOOKS.RARE'     ;kRARELOOKSRARExc.             .;R
LO'             .;oOKSRARELOOKSRAl.    .LOOKS.RARE.     :kRARELOOKSRAREo;.             'SR
LOOK;.            .,KSRARELOOKSRAx,     .;LOOKSR;.     .oSRARELOOKSRAo,.            .;OKSR
LOOKSk:.            .'RARELOOKSRARd;.      ....       'oOOOOOOOOOOxc'.            .:LOOKSR
LOOKSRARc.             .:dLOOKSRAREko;.            .,lxOOOOOOOOOd:.             .ARELOOKSR
LOOKSRARELo'             .;oOKSRARELOOxoc;,....,;:ldkOOOOOOOOkd;.             'SRARELOOKSR
LOOKSRARELOOd,.            .,lSRARELOOKSRARELOOKSRARELOOKSRkl,.            .,OKSRARELOOKSR
LOOKSRARELOOKSx;.            ..;oxELOOKSRARELOOKSRARELOkxl:..            .:LOOKSRARELOOKSR
LOOKSRARELOOKSRARc.              .':cOKSRARELOOKSRALOc;'.              .ARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELl'                 ...'',,,,''...                 'SRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOo,.                                          .,OKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSx;.                                      .;xOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSRLO:.                                  .:SRLOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSRLOOKl.                              .lOKSRLOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSRLOOKSRo'.                        .'oLOOKSRLOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSRLOOKSRARd;.                    .;xRELOOKSRLOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSRLOOKSRARELO:.                .:kRARELOOKSRLOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSRLOOKSRARELOOKl.            .cOKSRARELOOKSRLOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSRLOOKSRARELOOKSRo'        'oLOOKSRARELOOKSRLOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSRLOOKSRARELOOKSRARE,.  .,dRELOOKSRARELOOKSRLOOKSRARELOOKSRARELOOKSR
LOOKSRARELOOKSRARELOOKSRLOOKSRARELOOKSRARELOOKSRARELOOKSRARELOOKSRLOOKSRARELOOKSRARELOOKSR
 */
contract FacesOfLooksRare is ERC721, ERC2981, Ownable {
    using Strings for uint256;

    // Total supply of the collection
    uint256 public totalSupply;

    // First tokenId for baseURIs
    uint256[] internal _firstTokenIdBaseURIs;

    // BaseURIs
    string[] internal _baseURIs;

    event NewBaseURI(string baseURI, uint256 firstTokenId);
    event UpdateLastBaseURI(string baseURI, uint256 firstTokenId);
    event UpdateDefaultRoyalty(address receiver, uint96 feeNumerator);
    event UpdateTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator);

    /**
     * @notice Constructor
     * @param _baseURI first baseURI
     * @param _royaltyRecipient address of the royalty recipient
     * @param _feeNumerator default fee percentage of this collection (e.g., 2,000 = 20%)
     */
    constructor(
        string memory _baseURI,
        address _royaltyRecipient,
        uint96 _feeNumerator
    ) ERC721("Faces of LooksRare", "FLR") {
        _firstTokenIdBaseURIs.push(totalSupply);
        _baseURIs.push(_baseURI);
        _setDefaultRoyalty(_royaltyRecipient, _feeNumerator);
    }

    /**
     * @notice Add baseURI
     * @param _baseURI new baseURI
     */
    function addBaseURI(string memory _baseURI) external onlyOwner {
        require(_firstTokenIdBaseURIs[_firstTokenIdBaseURIs.length - 1] != totalSupply, "Owner: Cannot double push");
        _firstTokenIdBaseURIs.push(totalSupply);
        _baseURIs.push(_baseURI);

        emit NewBaseURI(_baseURI, totalSupply);
    }

    /**
     * @notice Batch mint new tokenIds
     * @param to array of receiver addresses
     */
    function batchMint(address[] memory to) external onlyOwner {
        uint256 numberTokens = to.length;
        require(numberTokens > 0, "Batch mint: Length must be > 0");

        for (uint256 i; i < numberTokens; i++) {
            _mint(to[i], totalSupply + i);
        }

        totalSupply += numberTokens;
    }

    /**
     * @notice Mint new tokenId
     * @param to receiver address
     */
    function mint(address to) external onlyOwner {
        _mint(to, totalSupply++);
    }

    /**
     * @notice Update default royalty
     * @param receiver address of the royalty receiver
     * @param feeNumerator fee percentage (e.g., 2,000 = 20%)
     */
    function updateDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        if (receiver == address(0) || feeNumerator == 0) {
            require(receiver == address(0) && feeNumerator == 0, "Royalty: Wrong parameters");
            _deleteDefaultRoyalty();
        } else {
            _setDefaultRoyalty(receiver, feeNumerator);
        }

        emit UpdateDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @notice Update last baseURI
     * @param _baseURI new baseURI
     * @param _firstTokenIdBaseURI tokenId for the first token using the baseURI
     */
    function updateLastBaseURI(string memory _baseURI, uint256 _firstTokenIdBaseURI) external onlyOwner {
        uint256 currentLength = _baseURIs.length;

        // First tokenId must always be 0
        if (currentLength > 1) {
            require(_firstTokenIdBaseURI > _firstTokenIdBaseURIs[currentLength - 2], "Update: TokenId must be higher");
            _firstTokenIdBaseURIs[currentLength - 1] = _firstTokenIdBaseURI;
        }

        _baseURIs[currentLength - 1] = _baseURI;

        emit UpdateLastBaseURI(_baseURI, _firstTokenIdBaseURIs[currentLength - 1]);
    }

    /**
     * @notice Update token-specific royalty
     * @param tokenId tokenId
     * @param receiver address of the royalty receiver
     * @param feeNumerator fee percentage (e.g., 2,000 = 20%)
     */
    function updateTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        require(_exists(tokenId), "Royalty: nonexistent token");

        if (receiver == address(0) || feeNumerator == 0) {
            require(receiver == address(0) && feeNumerator == 0, "Royalty: Wrong parameters");
            _resetTokenRoyalty(tokenId);
        } else {
            _setTokenRoyalty(tokenId, receiver, feeNumerator);
        }

        emit UpdateTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC2981, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory tokenURI_) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        for (uint256 i; i < _firstTokenIdBaseURIs.length; i++) {
            if (
                i + 1 == _firstTokenIdBaseURIs.length ||
                (tokenId >= _firstTokenIdBaseURIs[i] && tokenId < _firstTokenIdBaseURIs[i + 1])
            ) {
                tokenURI_ = string(abi.encodePacked(_baseURIs[i], tokenId.toString(), ".json"));
                return tokenURI_;
            }
        }
    }

    /**
     * @notice View baseURIs and first tokenIds
     * @param cursor cursor (should start at 0 for first request)
     * @param size size of the response (e.g., 50)
     */
    function viewBaseURIs(uint256 cursor, uint256 size)
        public
        view
        returns (
            string[] memory,
            uint256[] memory,
            uint256
        )
    {
        uint256 length = size;

        if (length > _baseURIs.length - cursor) {
            length = _baseURIs.length - cursor;
        }

        string[] memory baseURIs = new string[](length);
        uint256[] memory firstTokenIdBaseURIs = new uint256[](length);

        for (uint256 i; i < length; i++) {
            baseURIs[i] = _baseURIs[cursor + i];
            firstTokenIdBaseURIs[i] = _firstTokenIdBaseURIs[cursor + i];
        }

        return (baseURIs, firstTokenIdBaseURIs, cursor + length);
    }

    /**
     * @notice View number of distinct baseURIs
     */
    function viewCountBaseURIs() public view returns (uint256) {
        return _baseURIs.length;
    }
}
