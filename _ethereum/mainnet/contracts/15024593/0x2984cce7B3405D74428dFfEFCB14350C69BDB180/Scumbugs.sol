// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./OpenseaProxy.sol";

/**
* @notice Smart contract for Scumbugs.
* ╭━━━┳━━━┳╮╱╭┳━╮╭━┳━━╮╭╮╱╭┳━━━┳━━━╮
* ┃╭━╮┃╭━╮┃┃╱┃┃┃╰╯┃┃╭╮┃┃┃╱┃┃╭━╮┃╭━╮┃
* ┃╰━━┫┃╱╰┫┃╱┃┃╭╮╭╮┃╰╯╰┫┃╱┃┃┃╱╰┫╰━━╮
* ╰━━╮┃┃╱╭┫┃╱┃┃┃┃┃┃┃╭━╮┃┃╱┃┃┃╭━╋━━╮┃
* ┃╰━╯┃╰━╯┃╰━╯┃┃┃┃┃┃╰━╯┃╰━╯┃╰┻━┃╰━╯┃
* ╰━━━┻━━━┻━━━┻╯╰╯╰┻━━━┻━━━┻━━━┻━━━╯
*/

contract ScumbugsNFT is ERC721A("Scumbugs", "SCUMBUGS"), Pausable, ReentrancyGuard {

    address public proxyRegistryAddress;
    uint32 public constant supply = 11688;
    bool private isOpenSeaProxyActive = true;
    string private baseTokenURI;
    mapping(address => bool) public usedAddresses;
    mapping(address => bool) private ogs;

    /**
     * @notice Constructor.
     */
    constructor() {
        baseTokenURI = "https://www.api.scumbugs.net/metadata/";
        proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
        ogs[0x3adC0678b69A294e93BE04e8495C46BbF6EF9923] = true;
        ogs[0x5f1f648290a1cDf95cFf2CBF20b616B4029a7550] = true;
        ogs[0x81643e9D6c337a8D4637b220A88342221343d02A] = true;
        ogs[0xBDA96c5be2430d1D8c5e76605517b65bcC8BFb7c] = true;
        ogs[0xdF10f43bb5CAe33B0e44ceD84a23732fa56db743] = true;
        ogs[0x819884634b84B3F9B71abde27AD1C599D8327176] = true;
        ogs[0x94d727B34EfF4DD5814a3BB4921Cbe457F90FBfa] = true;
        ogs[0xf307df8f214752dA2c483137a2CcD24baF2Af76b] = true;
        ogs[0x90ef52263CdCFBa4A7BC25517482551E5B114251] = true;
        ogs[0xa34De24f2898f2250D38e7Be82ABB490DD29E0f0] = true;
        ogs[0xe5c2773Ce0f43CD33a4E2E6b45664a5782c8244F] = true;
        ogs[0xEa53d4D56e37678fa4FcfC2df5aEE8F559FCf4c9] = true;
        ogs[0x9A337d83a4c117D61938d1051f8792F4781bA22A] = true;
        ogs[0x583C4839F97eC375E1D72687e9616A03e616CF9D] = true;
        ogs[0xA442dDf27063320789B59A8fdcA5b849Cd2CDeAC] = true;
        ogs[0xBfF3C08a3D88F1A660b3427cb0287cAca8B0E727] = true;
        ogs[0x9d2C7cCB2dBee9154b1F1FF902196A99eA82b1F2] = true;
        ogs[0x969b4C148F459B3353A869531b5b5Cc6C0fAB3b4] = true;
        ogs[0x66009cD875aC66f98B07A422290e9b72BA8fD67c] = true;
        ogs[0xE33EeC26049f3B1b2d6697F8870e88dA33397704] = true;
        ogs[0xA75cbc940bdC40839121bb3955895E66aAfE9601] = true;
        ogs[0x2cEE318b1dE467EEa5164F5A5d9281B7F67A4F28] = true;
        ogs[0x7D065B47Ebc5da975fFE1d3a8cB52083BC5316D0] = true;
        ogs[0x992119CDE9596197d67421AA010b1D4D7e2FAf70] = true;
        ogs[0x82E8e9E21275861fb0733D654Dba0F1680DA99Ec] = true;
        ogs[0x654A7387bBC665a283a98f2819e9942bc734a4E7] = true;
        ogs[0x6CFab518eeD2486bdc5e8605471c7b1999157363] = true;
        ogs[0xEA688cDa0D70dB2C174Fd0FA96A58DA200aD198b] = true;
        ogs[0xFe097A6064439a92e76A57305B2c0F2f5f9FaC42] = true;
        ogs[0x849cc61626bdBE773653fCA5999Bb1E14Eb517B4] = true;
        ogs[0x358d7755aFbd225d254455aF79f24f9437F970E9] = true;
        ogs[0xa465376b3e3Ff7CA9F2F7786B55f13e2830f80DA] = true;
        ogs[0xAa1fdBc62c986ff4FbAAed412917966cFD9651FD] = true;
        ogs[0xC9f099C305825270e9c550AfC7633931fE1F3C73] = true;
        ogs[0xdB070Cf0b5c0355918f4F266B8FDBC91703575A9] = true;
        ogs[0x0260C74a0bB58dde08092140AC05bf1143abB5F7] = true;
        ogs[0x2a77543E0134869BbD0cb989AA07ADa85134F92f] = true;
        ogs[0x3dF00391bea3ba987D1c77432B6E6dfe87E95633] = true;
        ogs[0xA3c0E39EB2D888CE3C0281b40d768a769e6C7630] = true;
        ogs[0x4e83bD1Fe63BDdf16aE333BFffFB7C2a434FF138] = true;
        ogs[0xeF90DD7379d0217Be1564a1D8AE45B467b56d039] = true;
        ogs[0x5986182c9f1792d6483CA54E4C706B653F4b211b] = true;
        ogs[0xF39c22247766Bc68Eede35689B67c1f4180D30dc] = true;
        ogs[0x5dbF5B3bdF277D8e1E5AAa9343E4410f4c1bbb1B] = true;
        ogs[0x8F9c86C3f9a51029De7120F8Ef770cD4E54e0E88] = true;
        ogs[0x051D091c2cc2B84D5d262C0A92FE805f744Fec03] = true;
        ogs[0x655171a3AeD93AB0B5C68B9338189B0F6dBDe088] = true;
        ogs[0x59aAE3Cc895CeE98Dd25720F7b647A851dEdD202] = true;
        ogs[0x44c5fa6D89d8DE11081F881f4e44DEf37eEc2a4c] = true;
        ogs[0xe02eAa6222BEaa21a2A919f86f725Fa474e29f11] = true;
        ogs[0x4002E777974a1c45f7a94bd7F89f6b9889172bA6] = true;
        ogs[0xe4cf69a6BE7328D9BF4Dd9134cdB837D6f9148FA] = true;
        ogs[0x3Efc43867B0a662ce19156176d80dbe2c2454b69] = true;
        ogs[0x71a0F630462e594372223b1a5896aEcA10c2F68a] = true;
        ogs[0x33c2007a89CB045b5b8c7E30692F4fc00C18D3d2] = true;
        ogs[0xeAA31E52aca2AdEA4C6Da65A7024d71bAc6fb350] = true;
        ogs[0x8461b7A7E754241d50606694Fec9f2908e5f564A] = true;
        ogs[0x0E10C88253AD6cd55fb5F9bdf2773a21C2F02427] = true;
        ogs[0x78a46Aa423fc2ec136adca1F4185C55df177e0d6] = true;
        ogs[0xb560097756CE90872b9c75b4907A54834b6DeECB] = true;
        ogs[0xf48a881832132324F33550EAf3177f3E92908F3c] = true;
        ogs[0x072Aaa8BfDD3fa84F0F505c83c0704250e9B90A6] = true;
    }

    /**
     * @notice Mints new NFT(s).
     */
    function mint() external nonReentrant whenNotPaused {
        uint256 amount;
        if (ogs[msg.sender]) {
            amount = 6;
        } else {
            amount = 2;
        }
        require(!usedAddresses[msg.sender], "This address has already minted Scumbugs");
        require(msg.sender == tx.origin, "Real users only");
        require(_nextTokenId() + amount <= supply, "Can't mint that amount of NFTs");
        _safeMint(msg.sender, amount);
        usedAddresses[msg.sender] = true;
    }

    /**
     * @notice Mints new NFT(s) from owner
     */
    function mintFor(address to, uint256 amount) external whenNotPaused onlyOwner {
        require(_nextTokenId() + amount <= supply, "Can't mint that amount of NFTs");
        _safeMint(to, amount);
    }

    /**
     * @notice Returns if a NFT with given tokenId exists
     */
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function nextTokenId() public view returns (uint256) {
        return _nextTokenId();
    }

    /**
     * @dev Set baseTokenURI.
     */
    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /**
     * @dev Override _baseURI to return the right base uri.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev Sets value of proxyRegistryAddress.
     */
    function setProxyRegistryAddress(address _proxyRegistryAddress) public onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    // function to disable gasless listings for security in case
    // opensea ever shuts down or is compromised
    // from CryptoCoven https://etherscan.io/address/0x5180db8f5c931aae63c74266b211f580155ecac8#code
    function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive) public onlyOwner {
        isOpenSeaProxyActive = _isOpenSeaProxyActive;
    }

    /**
     * @dev Override isApprovedForAll to allowlist user's OpenSea proxy accounts to enable gas-less listings.
     * Taken from CryptoCoven: https://etherscan.io/address/0x5180db8f5c931aae63c74266b211f580155ecac8#code
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Get a reference to OpenSea's proxy registry contract by instantiating
        // the contract using the already existing address.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);

        if (isOpenSeaProxyActive && address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

}