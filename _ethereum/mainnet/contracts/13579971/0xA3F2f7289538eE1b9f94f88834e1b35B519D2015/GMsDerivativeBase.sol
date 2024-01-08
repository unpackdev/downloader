// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "./Strings.sol";
import "./GMsPassCore.sol";

/**
 * @title GMsDerivativeBase contract
 * @author wildmouse
 * @notice This contract provides basic functionalities to allow minting using the GMsPassCore
 * @dev This is hardcoded to the minting condition to deploy derivative NFTs only for Generativemasks holders without claim fees.
 *      This SHOULD be derived by another contract and used for mainnet deployments
 */
contract GMsDerivativeBase is GMsPassCore {

    using Strings for uint256;

    address public derivedFrom;
    string private __baseURI;

    /**
     * @notice Construct an GMsDerivativeBase instance
     * @param name Name of the token
     * @param symbol Symbol of the token
     * @param baseURI URL of metadata JSON. Token id will be added for each token id on tokenURL()
     * @param generativemasks Generativemasks address. This argument should hardcoded by derived contract.
     * @param _derivedFrom NFT contract address of the derivation source
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address generativemasks,
        address _derivedFrom
    )
    GMsPassCore(
        name,
        symbol,
        IERC721(generativemasks),
        true,
        10000,
        10000,
        0,
        0
    )
    {
        __baseURI = baseURI;
        derivedFrom = _derivedFrom;
    }

    function _baseURI() internal override view virtual returns (string memory) {
        return __baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        uint256 maskNumber = (tokenId + METADATA_INDEX) % GMS_SUPPLY_AMOUNT;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, maskNumber.toString())) : "";
    }

    function updateBaseURI(string calldata newBaseURI) external onlyOwner {
        __baseURI = newBaseURI;
    }
}
