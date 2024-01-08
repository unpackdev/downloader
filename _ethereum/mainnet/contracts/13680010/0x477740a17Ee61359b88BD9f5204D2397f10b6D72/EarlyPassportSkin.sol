// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC721Enumerable.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract EarlyPassportSkin is ERC721, Ownable {
    using Counters for Counters.Counter;

    /* ========== Events ========== */

    event BaseURISet(string _uri);

    event PassportIDThresholdSet(uint256 _threshold);

    /* ========== Variables ========== */

    Counters.Counter private _tokenIdCounter;

    string public baseURI;

    uint256 public passportIdThreshold;

    IERC721Enumerable public defiPassport;

    mapping (address => bool) public usersAlreadyMinted;

    /* ========== Constructor ========== */

    constructor(
        address _defiPassport
    ) 
        ERC721("EarlyPassportSkin", "EPS") 
    {
        defiPassport = IERC721Enumerable(_defiPassport);
    }


    /* ========== Restricted functions ========== */

    function setBaseURI(string memory _uri) 
        external
        onlyOwner
    {
        baseURI = _uri;
        emit BaseURISet(_uri);
    }

    function setPassportIdThreshold(uint256 _threshold) 
        external
        onlyOwner
    {
        passportIdThreshold = _threshold;

        emit PassportIDThresholdSet(_threshold);
    }
    
    /* ========== Public functions ========== */

    function safeMint(address _to) 
        public 
    {
        require (
            !usersAlreadyMinted[_to],
            "EarlyPassportSkin: user has already minted the skin"
        );
        
        // The call to tokenOfOwnerByIndex will revert if the user does not have a token
        uint256 passportId = defiPassport.tokenOfOwnerByIndex(_to, 0);

        require (
            passportId <= passportIdThreshold,
            "EarlyPassportSkin: passport ID is too high"
        );

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        usersAlreadyMinted[_to] = true;
        _safeMint(_to, tokenId);
    }

    /* ========== Private functions ========== */

    function _baseURI()
        internal
        view
        override
        returns (string memory)
    {
        return baseURI;
    }
}
