// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./MultiCaller.sol";

contract TheMagnificent is ERC721, Ownable, ReentrancyGuard, MultiCaller {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public maxAmountOfTokens;
    string public baseURI;
    string public baseContractURI;
    bool public isBaseURIFinal = false;
    bool public isMaxSupplyLocked = false;

    // Events
    event PermanentURI(string _value, uint256 indexed _id);
    event MaxSupplyLocked(bool _value);
    event BaseURILocked(bool _value);

    constructor() ERC721("The Magnificent", "MAGN") {
        setBaseURI("https://api.themagnificent.xyz/token/", false);
        baseContractURI = "https://api.themagnificent.xyz/contract";

        // Depending on the demands of the creative process, we do not completely rule out the
        // idea of reducing it but never raising it. At some point, this value will be frozen.
        maxAmountOfTokens = 314;
    }

    /**
     * @notice Create a new token if the max supply allows it.
     * @param _owner The address to mint the token to
     */
    function mintCollectable(address _owner) public onlyOwner {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        require(newItemId <= maxAmountOfTokens, "Too many tokens created");
        _mint(_owner, newItemId);
        if (isBaseURIFinal) {
            emit PermanentURI(tokenURI(newItemId), newItemId);
        }
    }

    /**
     * @notice Emit a PermanentURI event if the URI is final.
     * @dev This function is here to emit these events for tokens minted before the URI was final
     * if needed by any off-chain infrastructure.
     * @param _id The token ID to emit the URI for
     */
    function notifyPermanentURI(uint256 _id) public onlyOwner {
        require(isBaseURIFinal, "Base URI is not final");
        emit PermanentURI(tokenURI(_id), _id);
    }

    // Internal functions
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // Setters
    // Set the contract metadata base URI. Tokens are unaffected.
    function setBaseContractURI(string memory _newBaseURIContractURI) public virtual onlyOwner {
        baseContractURI = _newBaseURIContractURI;
    }

    // Set base URI if it isn't already frozen.
    function setBaseURI(string memory _newBaseURI, bool isFinal) public virtual onlyOwner {
        require(!isBaseURIFinal);
        baseURI = _newBaseURI;
        if (isFinal) {
            isBaseURIFinal = isFinal;
            emit BaseURILocked(true);
        }
    }

    // Set the maximum number of collectible tokens that can be produced and, if necessary, lock this value.
    function setMaxAmountOfTokens(uint256 _maxAmountOfTokens, bool lockMaxSupply) public onlyOwner {
        require(!isMaxSupplyLocked);
        require(_maxAmountOfTokens < maxAmountOfTokens);
        maxAmountOfTokens = _maxAmountOfTokens;
        if (lockMaxSupply) {
            isMaxSupplyLocked = lockMaxSupply;
            emit MaxSupplyLocked(true);
        }
    }

    // Getters
    function contractURI() public view returns (string memory) {
        return baseContractURI;
    }
}
