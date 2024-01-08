// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

/**
 * 

 ,--.--------.               _,.---._                                    _,---.                _,.----.  ,--.-.,-.   .=-.-..-._        .--.-.         ,--.--------.              .-._           ,----.    ,-,--.  
/==/,  -   , -\.-.,.---.   ,-.' , -  `.    _.-.      _.-.             .-`.' ,  \ .--.-. .-.-..' .' -   \/==/- |\  \ /==/_ /==/ \  .-._/==/  /        /==/,  -   , -\.--.-. .-.-./==/ \  .-._ ,-.--` , \ ,-.'-  _\ 
\==\.-.  - ,-./==/  `   \ /==/_,  ,  - \ .-,.'|    .-,.'|            /==/_  _.-'/==/ -|/=/  /==/  ,  ,-'|==|_ `/_ /|==|, ||==|, \/ /, |==\ -\        \==\.-.  - ,-./==/ -|/=/  ||==|, \/ /, /==|-  _.-`/==/_ ,_.' 
 `--`\==\- \ |==|-, .=., |==|   .=.     |==|, |   |==|, |           /==/-  '..-.|==| ,||=| -|==|-   |  .|==| ,   / |==|  ||==|-  \|  | \==\- \        `--`\==\- \  |==| ,||=| -||==|-  \|  ||==|   `.-.\==\  \    
      \==\_ \|==|   '='  /==|_ : ;=:  - |==|- |   |==|- |           |==|_ ,    /|==|- | =/  |==|_   `-' \==|-  .|  |==|- ||==| ,  | -|  `--`-'             \==\_ \ |==|- | =/  ||==| ,  | -/==/_ ,    / \==\ -\   
      |==|- ||==|- ,   .'|==| , '='     |==|, |   |==|, |           |==|   .--' |==|,  \/ - |==|   _  , |==| _ , \ |==| ,||==| -   _ |                     |==|- | |==|,  \/ - ||==| -   _ |==|    .-'  _\==\ ,\  
      |==|, ||==|_  . ,'. \==\ -    ,_ /|==|- `-._|==|- `-._        |==|-  |    |==|-   ,   |==\.       /==/  '\  ||==|- ||==|  /\ , |                     |==|, | |==|-   ,   /|==|  /\ , |==|_  ,`-._/==/\/ _ | 
      /==/ -//==/  /\ ,  ) '.='. -   .' /==/ - , ,/==/ - , ,/       /==/   \    /==/ , _  .' `-.`.___.-'\==\ /\=\.'/==/. //==/, | |- |                     /==/ -/ /==/ , _  .' /==/, | |- /==/ ,     /\==\ - , / 
      `--`--``--`-`--`--'    `--`--''   `--`-----'`--`-----'        `--`---'    `--`..---'               `--`      `--`-` `--`./  `--`                     `--`--` `--`..---'   `--`./  `--`--`-----``  `--`---'  
      

    you can do whatever the fuck you want with this tune, ya fucking troll
 */

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

abstract contract FuckinTrolls {
    function ownerOf(uint256 tokenId) public virtual view returns (address);
    function balanceOf(address owner) external virtual view returns (uint256 balance);
}

/**
 * @title TrollTunes
 * @dev 10,003 generatively created sounds for all the FuckinTrolls
 */
contract TrollTunes is ERC721, Ownable, ReentrancyGuard {
    FuckinTrolls private fuckinTrolls;

    // Address of interface identifier for royalty standard
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    // Address of payment splitter contract
    address public beneficiary;

    // Boolean value to activate claiming period for public
    bool public publicClaimPeriod = false;

    // Current number of tokens claimed
    uint256 public totalClaimed = 0;

    /**
     * @dev Initializes contract and sets initial baseURI and beneficiary
     * @param _beneficiary Address of payment splitter contract
     * @param _fuckinTrolls Fuckin Trolls contract
     */
    constructor(
        address _beneficiary,
        FuckinTrolls _fuckinTrolls
    ) ERC721("Troll Fuckin' Tunes", "TUNES") {
        beneficiary = _beneficiary;
        fuckinTrolls = _fuckinTrolls;
    }

    /**
     * @dev Mints a list of tokens in a single transaction
     * @param _tokenIds List of token IDs set to be claimed by trolls owners
     *
     * Requirements:
     *
     * - `balance` of _msgSender must be greater than 0
     */
    function trollsClaim(uint256[] memory _tokenIds) public nonReentrant {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            if (fuckinTrolls.ownerOf(tokenId) == _msgSender() && !_exists(tokenId)) {
                _claim(_msgSender(), tokenId);
            }
        }
    }

    /**
     * @dev Mints a single token in a single transaction
     * @param _tokenId Token ID set to be claimed by public
     *
     * Requirements:
     *
     * - `publicClaimPeriod` must be set to true
     */
    function publicClaim(uint256 _tokenId) public nonReentrant {
        require(publicClaimPeriod == true, "Public claiming has not yet been activated");
        require(!_exists(_tokenId), "Token has already been claimed");

        _claim(_msgSender(), _tokenId);
    }
    
    function _claim(address _owner, uint256 _tokenId) internal {
        _mint(_owner, _tokenId);
        totalClaimed += 1;
    }

    /**
     * @dev See {IERC721-baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return "ipfs://QmeW7CJTwFGmjKHKCZH7uQznvv1Tpi17SVSFHFcPXz5ZYp/";
    }

    /**
     * @dev Sets the trolls and public claim periods
     * @param _public Boolean value for activating or terminating the public claim period
     *
     * Requirements:
     *
     * - `owner` must be function caller
     */
    function setClaimPeriod(bool _public) public onlyOwner {
        publicClaimPeriod = _public;
    }

    /**
     * @dev See {IERC2981-royaltyInfo}.
     */
    function royaltyInfo(uint256 /* _tokenId */, uint256 _salePrice) external view returns (address, uint256 royaltyAmount) {
        royaltyAmount = (_salePrice * 4) / 100;

        return (beneficiary, royaltyAmount);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId);
    }
}
