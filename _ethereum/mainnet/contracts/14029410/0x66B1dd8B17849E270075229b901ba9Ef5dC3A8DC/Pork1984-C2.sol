// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";
import "./IERC721.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Pork1984ChapterII is ERC721, Pausable, Ownable, ERC721Burnable, ContextMixin, NativeMetaTransaction {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string baseURI_;
    address proxyRegistryAddress;
    address genesisPork1984Address;
    mapping(uint256 => uint256) genesisTokensToChapter2MintedTokens;
    IERC721 genesisPork1984Contract;

    constructor(address _proxyRegistryAddress, address _genesisPork1984Address) ERC721("Pork1984 Chapter II", "PORK1984-C2") {
        proxyRegistryAddress = _proxyRegistryAddress;
        genesisPork1984Address = _genesisPork1984Address;
        genesisPork1984Contract = IERC721(_genesisPork1984Address);
        setBaseURI("https://api.pork1984.io/api/chapter2/");
        _pause();
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI_;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseURI_ = baseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getChapter2TokenIdForGenesisTokenId(uint256 genesisTokenId) public view returns(uint256) {
        return genesisTokensToChapter2MintedTokens[genesisTokenId];
    }

    function canMintForGenesisToken(uint256 tokenId) public view returns(bool) {
        return genesisTokensToChapter2MintedTokens[tokenId] == 0;
    }

    function canMintForGenesisTokens(uint256[] memory genesisTokenIds) public view returns(bool) {
        for (uint256 i = 0; i < genesisTokenIds.length; i++) {
            if (!canMintForGenesisToken(genesisTokenIds[i])) {
                return false;
            }
        }
        return true;
    }

    function _mintForGenesisTokenUnconditionally(uint256 genesisTokenId, address to) internal {
        _tokenIdCounter.increment();
        genesisTokensToChapter2MintedTokens[genesisTokenId] = _tokenIdCounter.current();
        _safeMint(to, _tokenIdCounter.current());
    }

    function _mintForGenesisToken(uint256 genesisTokenId, address to) internal {
        require(genesisPork1984Contract.ownerOf(genesisTokenId) == to, "Cannot mint a Chapter 2 token for given genesis token because it is not yours");

        _mintForGenesisTokenUnconditionally(genesisTokenId, to);
    }

    function giveForGenesisTokens(uint256[] memory genesisTokenIds, address to) public onlyOwner {
        for (uint256 i = 0; i < genesisTokenIds.length; i++) {
            _mintForGenesisToken(genesisTokenIds[i], to);
        }
    }

    function mintForGenesisToken(uint256 genesisTokenId) public whenNotPaused {
        require(canMintForGenesisToken(genesisTokenId), "Cannot mint a Chapter 2 token for given genesis token because it is already used");
        _mintForGenesisToken(genesisTokenId, msg.sender);
    }

    function mintForGenesisTokens(uint256[] memory genesisTokenIds) public whenNotPaused {
        for (uint256 i = 0; i < genesisTokenIds.length; i++) {
            mintForGenesisToken(genesisTokenIds[i]);
        }
    }

 /*
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
*/

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }

    /**
     * First version of Chapter2 smart contract consumed a lot of gas
     * In the second version we want to give tokens for free to those who minted in the first version
     */
    function giveTokensForOwnersInPreviousVersion() public onlyOwner {
        require(totalSupply() == 0, "Tokens are given");
        _mintForGenesisTokenUnconditionally(6115, 0xdca119aB841e632f8bC9AA003Dccdeba9C6d2907);
        _mintForGenesisTokenUnconditionally(3261, 0xe4F28b2D2e4D380C09FEf46d9FEFE5834bF49271);
        _mintForGenesisTokenUnconditionally(4640, 0xEC58E527a9973FAe553e89CD7A6385015649cA26);
        _mintForGenesisTokenUnconditionally(6526, 0xE4DA5Af777455fc91C3C5C7732eeb08f89988bd0);
        _mintForGenesisTokenUnconditionally(6877, 0xF6559137c62dC4A686499144FC828E69e3B0f636);
        _mintForGenesisTokenUnconditionally(7239, 0x1a072A0ae89e8C4565c31083c6B2E8A2Ee58c3FC);
        _mintForGenesisTokenUnconditionally(7377, 0xD269d1af98D27B76a55D2bE4e829e7cCF5f9223D);
        _mintForGenesisTokenUnconditionally(7381, 0xDDebA68B2e3e0f2C56A63F4a9ADD6978C167024E);
        _mintForGenesisTokenUnconditionally(6751, 0xC536bF5B44A60C2094e8D6590990FF5680983f6d);
        _mintForGenesisTokenUnconditionally(675, 0x2A82a5989E24FC36Dade60e80A94A5D428926321);
        _mintForGenesisTokenUnconditionally(676, 0x2A82a5989E24FC36Dade60e80A94A5D428926321);
        _mintForGenesisTokenUnconditionally(677, 0x2A82a5989E24FC36Dade60e80A94A5D428926321);
        _mintForGenesisTokenUnconditionally(990, 0x2A82a5989E24FC36Dade60e80A94A5D428926321);
        _mintForGenesisTokenUnconditionally(3115, 0x2A82a5989E24FC36Dade60e80A94A5D428926321);
        _mintForGenesisTokenUnconditionally(1422, 0xdca119aB841e632f8bC9AA003Dccdeba9C6d2907);
        _mintForGenesisTokenUnconditionally(5517, 0xdca119aB841e632f8bC9AA003Dccdeba9C6d2907);
        _mintForGenesisTokenUnconditionally(7024, 0x93b526C2f4fC4C8B286DAf64FA90E65eB3A6BCC2);
        _mintForGenesisTokenUnconditionally(7326, 0x0c183b19cf8a07bB4319729150b0b3B4841C0866);
        _mintForGenesisTokenUnconditionally(6635, 0x0c183b19cf8a07bB4319729150b0b3B4841C0866);
        _mintForGenesisTokenUnconditionally(6470, 0x7C7080e827556F7b97fA45176BDFa55dB3B86522);
        _mintForGenesisTokenUnconditionally(4352, 0x2791457F44027AE14fe8C61187aB04904b855335);
        _mintForGenesisTokenUnconditionally(4353, 0x2791457F44027AE14fe8C61187aB04904b855335);
        _mintForGenesisTokenUnconditionally(5706, 0x3c2774a512eF03a2D88417565E8dd5D30b64A05f);
        _mintForGenesisTokenUnconditionally(7372, 0xf86216e4e265A21dD5fD15371E821eA1dED5FC62);
        _mintForGenesisTokenUnconditionally(6696, 0xbD2995C0755139D2FF5D766aE93EbB7616276869);
        _mintForGenesisTokenUnconditionally(4097, 0xb89E9C6A4eDE53d6988747d1a1706342070cd568);
        _mintForGenesisTokenUnconditionally(4098, 0xb89E9C6A4eDE53d6988747d1a1706342070cd568);
        _mintForGenesisTokenUnconditionally(4099, 0xb89E9C6A4eDE53d6988747d1a1706342070cd568);
        _mintForGenesisTokenUnconditionally(6370, 0x560b6bB54fC0375c8a1C2CBD93B3a924e191E11B);
        _mintForGenesisTokenUnconditionally(1860, 0x560b6bB54fC0375c8a1C2CBD93B3a924e191E11B);
        _mintForGenesisTokenUnconditionally(7384, 0x560b6bB54fC0375c8a1C2CBD93B3a924e191E11B);
        _mintForGenesisTokenUnconditionally(7383, 0x560b6bB54fC0375c8a1C2CBD93B3a924e191E11B);
        _mintForGenesisTokenUnconditionally(5498, 0xC71B9c97a27fb2Cd0d98D449e75a63cBA312466D);
        _mintForGenesisTokenUnconditionally(5499, 0xC71B9c97a27fb2Cd0d98D449e75a63cBA312466D);
        _mintForGenesisTokenUnconditionally(4864, 0x0466C648A159d535686FcAaDCd5cD9987B5e08f0);
        _mintForGenesisTokenUnconditionally(2679, 0x0466C648A159d535686FcAaDCd5cD9987B5e08f0);
        _mintForGenesisTokenUnconditionally(2674, 0x0466C648A159d535686FcAaDCd5cD9987B5e08f0);
        _mintForGenesisTokenUnconditionally(714, 0x2bcBA14f244928B2f9d78a5727DCc109B541e39f);
        _mintForGenesisTokenUnconditionally(7142, 0xcF4A4071aE4C4a6d7920c758b3a524064787E2Db);
        _mintForGenesisTokenUnconditionally(7153, 0x1C78B6FD84467eF269aD7C4F5EAbe4ca5085Bf25);
        _mintForGenesisTokenUnconditionally(7117, 0x1C78B6FD84467eF269aD7C4F5EAbe4ca5085Bf25);
        _mintForGenesisTokenUnconditionally(7084, 0x1C78B6FD84467eF269aD7C4F5EAbe4ca5085Bf25);
        _mintForGenesisTokenUnconditionally(5059, 0x1C78B6FD84467eF269aD7C4F5EAbe4ca5085Bf25);
        _mintForGenesisTokenUnconditionally(7380, 0x8CDA054c36562f4a0a3A77a7fb20B9d333D245b0);
        _mintForGenesisTokenUnconditionally(6736, 0x8CDA054c36562f4a0a3A77a7fb20B9d333D245b0);
        _mintForGenesisTokenUnconditionally(6458, 0x8CDA054c36562f4a0a3A77a7fb20B9d333D245b0);
        _mintForGenesisTokenUnconditionally(7348, 0xb0d7a8Ac2FE42eDF4934dDDcDB33934457DAE397);
        _mintForGenesisTokenUnconditionally(7258, 0x8CDF560Cb6eaBBD54E46688d5fa4404364bE8f34);
        _mintForGenesisTokenUnconditionally(5937, 0x8a0B00f402E38F9BDf3e4226FAd9F4EdE0Dd3Cb4);
        _mintForGenesisTokenUnconditionally(133, 0x3a2Ea5595098565e7362e04dA30C5ec29435731F);
        _mintForGenesisTokenUnconditionally(140, 0x3a2Ea5595098565e7362e04dA30C5ec29435731F);
        _mintForGenesisTokenUnconditionally(4856, 0x3a2Ea5595098565e7362e04dA30C5ec29435731F);
        _mintForGenesisTokenUnconditionally(5712, 0x3a2Ea5595098565e7362e04dA30C5ec29435731F);
        _mintForGenesisTokenUnconditionally(5666, 0x3a2Ea5595098565e7362e04dA30C5ec29435731F);
        _mintForGenesisTokenUnconditionally(5657, 0x3a2Ea5595098565e7362e04dA30C5ec29435731F);
        _mintForGenesisTokenUnconditionally(2196, 0x044505d09d0f77499e4262A51EfE508188E0Ba94);
        _mintForGenesisTokenUnconditionally(724, 0x044505d09d0f77499e4262A51EfE508188E0Ba94);
        _mintForGenesisTokenUnconditionally(6452, 0x8CDF560Cb6eaBBD54E46688d5fa4404364bE8f34);
        _mintForGenesisTokenUnconditionally(7368, 0x35d04cbB7a465fc3B7A80887A19447B8A82D727D);
        _mintForGenesisTokenUnconditionally(7371, 0x35d04cbB7a465fc3B7A80887A19447B8A82D727D);
        _mintForGenesisTokenUnconditionally(5667, 0x3a2Ea5595098565e7362e04dA30C5ec29435731F);
        _mintForGenesisTokenUnconditionally(5668, 0x3a2Ea5595098565e7362e04dA30C5ec29435731F);
        _mintForGenesisTokenUnconditionally(5654, 0x3a2Ea5595098565e7362e04dA30C5ec29435731F);
        _mintForGenesisTokenUnconditionally(5658, 0x3a2Ea5595098565e7362e04dA30C5ec29435731F);
        _mintForGenesisTokenUnconditionally(5663, 0x3a2Ea5595098565e7362e04dA30C5ec29435731F);
        _mintForGenesisTokenUnconditionally(5669, 0x3a2Ea5595098565e7362e04dA30C5ec29435731F);
        _mintForGenesisTokenUnconditionally(7370, 0x35d04cbB7a465fc3B7A80887A19447B8A82D727D);
        _mintForGenesisTokenUnconditionally(7154, 0x35d04cbB7a465fc3B7A80887A19447B8A82D727D);
        _mintForGenesisTokenUnconditionally(7150, 0x35d04cbB7a465fc3B7A80887A19447B8A82D727D);
        _mintForGenesisTokenUnconditionally(7149, 0x35d04cbB7a465fc3B7A80887A19447B8A82D727D);
        _mintForGenesisTokenUnconditionally(7095, 0x35d04cbB7a465fc3B7A80887A19447B8A82D727D);
        _mintForGenesisTokenUnconditionally(2976, 0x3F049E5850229d18f01460DFda38c3ea6422b5a4);
        _mintForGenesisTokenUnconditionally(2975, 0x3F049E5850229d18f01460DFda38c3ea6422b5a4);
        _mintForGenesisTokenUnconditionally(2974, 0x3F049E5850229d18f01460DFda38c3ea6422b5a4);
        _mintForGenesisTokenUnconditionally(2973, 0x3F049E5850229d18f01460DFda38c3ea6422b5a4);
        _mintForGenesisTokenUnconditionally(2972, 0x3F049E5850229d18f01460DFda38c3ea6422b5a4);
        _mintForGenesisTokenUnconditionally(6856, 0x7c1939d092CD82D9E99B2E041fD84c9E5AF133C5);
        _mintForGenesisTokenUnconditionally(6858, 0x7c1939d092CD82D9E99B2E041fD84c9E5AF133C5);
        _mintForGenesisTokenUnconditionally(4578, 0xFf40ad3c852e4F18E65968388AAE5E94fb1cba25);
        _mintForGenesisTokenUnconditionally(4584, 0xFf40ad3c852e4F18E65968388AAE5E94fb1cba25);
        _mintForGenesisTokenUnconditionally(4585, 0xFf40ad3c852e4F18E65968388AAE5E94fb1cba25);
        _mintForGenesisTokenUnconditionally(75, 0xFf40ad3c852e4F18E65968388AAE5E94fb1cba25);
        _mintForGenesisTokenUnconditionally(2971, 0x3F049E5850229d18f01460DFda38c3ea6422b5a4);
        _mintForGenesisTokenUnconditionally(2970, 0x3F049E5850229d18f01460DFda38c3ea6422b5a4);
        _mintForGenesisTokenUnconditionally(2969, 0x3F049E5850229d18f01460DFda38c3ea6422b5a4);
        _mintForGenesisTokenUnconditionally(2968, 0x3F049E5850229d18f01460DFda38c3ea6422b5a4);
        _mintForGenesisTokenUnconditionally(2967, 0x3F049E5850229d18f01460DFda38c3ea6422b5a4);
        _mintForGenesisTokenUnconditionally(7280, 0x6c10c4A8E7D71a27ccA1Ec3843E0e9AFc88C523c);
        _mintForGenesisTokenUnconditionally(838, 0xf9570Eb74727A6e08562C3ef799876706d86A5E2);
        _mintForGenesisTokenUnconditionally(6744, 0x20C1c718640d9aDe58f1DD26a64EC366C34EDCd7);
        _mintForGenesisTokenUnconditionally(76, 0x053975c22772aB3ECd783D92DBaB0bD16E964070);
        _mintForGenesisTokenUnconditionally(4088, 0xb10DAA8b5291423745c5480d6cC412E0C1a56178);
        _mintForGenesisTokenUnconditionally(6562, 0xdE98445B4148dbe540308eB9FC40c0CDD3318Ef8);
        _mintForGenesisTokenUnconditionally(4222, 0xC637548f402887fBD999774dB8740c18efD43722);
        _mintForGenesisTokenUnconditionally(5337, 0xC637548f402887fBD999774dB8740c18efD43722);
        _mintForGenesisTokenUnconditionally(5767, 0xC637548f402887fBD999774dB8740c18efD43722);
        _mintForGenesisTokenUnconditionally(1198, 0x9A4740B0A5AdBE601188568B8f4Acf52333E4dC0);
        _mintForGenesisTokenUnconditionally(4470, 0xCB8b2c541E18AdBC8B4B8A42a3CA769f4EB72e6C);
        _mintForGenesisTokenUnconditionally(7374, 0xB26F5A229e3331528836E544a0F7b5ADb17CB114);
        _mintForGenesisTokenUnconditionally(4997, 0xD9251159B7F461C1306A1bAD855aE0c504acd3CA);
        _mintForGenesisTokenUnconditionally(804, 0x07794A44767928C3E4e862434589D5A89A1c6275);
        _mintForGenesisTokenUnconditionally(5199, 0x052F2567Da498C06dC591Ac48e0B56a07b28Bba2);
        _mintForGenesisTokenUnconditionally(5356, 0x052F2567Da498C06dC591Ac48e0B56a07b28Bba2);
        _mintForGenesisTokenUnconditionally(3968, 0x052F2567Da498C06dC591Ac48e0B56a07b28Bba2);
        _mintForGenesisTokenUnconditionally(4545, 0x67eDdB0c3217BC86A3eB26331E2eb545460DB0D8);
        _mintForGenesisTokenUnconditionally(5612, 0x67eDdB0c3217BC86A3eB26331E2eb545460DB0D8);
        _mintForGenesisTokenUnconditionally(6388, 0xC64EFe60570D60a7c2EE646a5Fcd0aD7bFE434DA);
        _mintForGenesisTokenUnconditionally(6389, 0xC64EFe60570D60a7c2EE646a5Fcd0aD7bFE434DA);
        _mintForGenesisTokenUnconditionally(6390, 0xC64EFe60570D60a7c2EE646a5Fcd0aD7bFE434DA);
        _mintForGenesisTokenUnconditionally(4709, 0x8c8A840Dd85c1fD98Bb57fd7DfF8647724f64672);
        _mintForGenesisTokenUnconditionally(6485, 0xf7D7b609791666dbD591AB5C3dc4644Ff77071dF);
        _mintForGenesisTokenUnconditionally(6660, 0x5C3EC66c2a7C77828E0f41300235304a6F934e4e);
        _mintForGenesisTokenUnconditionally(6662, 0x5C3EC66c2a7C77828E0f41300235304a6F934e4e);
        _mintForGenesisTokenUnconditionally(6659, 0x5C3EC66c2a7C77828E0f41300235304a6F934e4e);
        _mintForGenesisTokenUnconditionally(6661, 0x5C3EC66c2a7C77828E0f41300235304a6F934e4e);
        _mintForGenesisTokenUnconditionally(3573, 0xC3EFB1B3bEDe144f805aA3caCf5299dabC683Db5);
        _mintForGenesisTokenUnconditionally(3118, 0xC3EFB1B3bEDe144f805aA3caCf5299dabC683Db5);
        _mintForGenesisTokenUnconditionally(3448, 0xC3EFB1B3bEDe144f805aA3caCf5299dabC683Db5);
        _mintForGenesisTokenUnconditionally(3116, 0xC3EFB1B3bEDe144f805aA3caCf5299dabC683Db5);
        _mintForGenesisTokenUnconditionally(6699, 0xD1932153081496e444626C1334d14759b1218dD8);
        _mintForGenesisTokenUnconditionally(694, 0x34E46bD7a1b00D42b5A409B6EC310982C09d0D9D);
        _mintForGenesisTokenUnconditionally(2512, 0x34E46bD7a1b00D42b5A409B6EC310982C09d0D9D);
        _mintForGenesisTokenUnconditionally(6740, 0x7C7080e827556F7b97fA45176BDFa55dB3B86522);
        _mintForGenesisTokenUnconditionally(4620, 0xe4E873664f214a07708EbEF8A839cdA2e5f59334);
        _mintForGenesisTokenUnconditionally(6741, 0x7C7080e827556F7b97fA45176BDFa55dB3B86522);
        _mintForGenesisTokenUnconditionally(6870, 0x7C7080e827556F7b97fA45176BDFa55dB3B86522);
        _mintForGenesisTokenUnconditionally(6871, 0x7C7080e827556F7b97fA45176BDFa55dB3B86522);
        _mintForGenesisTokenUnconditionally(6872, 0x7C7080e827556F7b97fA45176BDFa55dB3B86522);
        _mintForGenesisTokenUnconditionally(6873, 0x7C7080e827556F7b97fA45176BDFa55dB3B86522);
        _mintForGenesisTokenUnconditionally(88, 0xd8BeF02A418Bbc5D550963E825Bf4d8B7D479dd8);
        _mintForGenesisTokenUnconditionally(5054, 0xd8BeF02A418Bbc5D550963E825Bf4d8B7D479dd8);
    }


}
