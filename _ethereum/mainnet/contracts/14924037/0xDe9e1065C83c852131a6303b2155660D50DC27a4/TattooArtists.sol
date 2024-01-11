// SPDX-License-Identifier: MIT
//   /$$$$$$$$          /$$     /$$
//  |__  $$__/         | $$    | $$
//     | $$  /$$$$$$  /$$$$$$ /$$$$$$    /$$$$$$   /$$$$$$
//     | $$ |____  $$|_  $$_/|_  $$_/   /$$__  $$ /$$__  $$
//     | $$  /$$$$$$$  | $$    | $$    | $$  \ $$| $$  \ $$
//     | $$ /$$__  $$  | $$ /$$| $$ /$$| $$  | $$| $$  | $$
//     | $$|  $$$$$$$  |  $$$$/|  $$$$/|  $$$$$$/|  $$$$$$/
//     |__/ \_______/   \___/   \___/   \______/  \______/
//
//
//
//    /$$$$$$              /$$     /$$             /$$
//   /$$__  $$            | $$    |__/            | $$
//  | $$  \ $$  /$$$$$$  /$$$$$$   /$$  /$$$$$$$ /$$$$$$   /$$$$$$$
//  | $$$$$$$$ /$$__  $$|_  $$_/  | $$ /$$_____/|_  $$_/  /$$_____/
//  | $$__  $$| $$  \__/  | $$    | $$|  $$$$$$   | $$   |  $$$$$$
//  | $$  | $$| $$        | $$ /$$| $$ \____  $$  | $$ /$$\____  $$
//  | $$  | $$| $$        |  $$$$/| $$ /$$$$$$$/  |  $$$$//$$$$$$$/
//  |__/  |__/|__/         \___/  |__/|_______/    \___/ |_______/
//
// Author: Martin, Mike, Christian

pragma solidity >=0.8.0 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ECDSA.sol";

contract TattooArtists is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public _baseTokenURI;
    string public hiddenMetadataUri;

    uint256 public cost = 0.0045 ether;
    uint256 public freemint_supply = 0;
    uint256 public maxMintAmountPerTx = 20;
    uint256 public maxSupply = 4165;
    bool public paused = false;
    bool public revealed;

    bool public isSignature = true;

    constructor(string memory _hiddenMetadataUri)
        ERC721A("Alien Inkling", "AI")
    {
        setHiddenMetadataUri(_hiddenMetadataUri);
        Airdrop();
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function mint(
        uint256 _mintAmount,
        uint256 _timestamp,
        bytes memory _signature
    ) public payable nonReentrant {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        require(!paused, "The contract is paused!");
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");

        address wallet = _msgSender();
        if (isSignature) {
            address signerOwner = signatureWallet(
                wallet,
                _mintAmount,
                _timestamp,
                _signature
            );
            require(signerOwner == owner(), "Not authorized to mint");

            require(block.timestamp >= _timestamp - 30, "Out of time");

            _safeMint(wallet, _mintAmount);
        } else {
            _safeMint(wallet, _mintAmount);
        }
        payable(owner()).transfer(msg.value);
    }

    function setSignature(bool _isSignature) public onlyOwner {
        isSignature = _isSignature;
    }

    function signatureWallet(
        address wallet,
        uint256 _tokenAmount,
        uint256 _timestamp,
        bytes memory _signature
    ) public pure returns (address) {
        return
            ECDSA.recover(
                keccak256(abi.encode(wallet, _tokenAmount, _timestamp)),
                _signature
            );
    }
    function freeMintAirdrop(
        address _address,
        uint256 _mintAmount
    ) public nonReentrant {
        require(!paused, "The contract is paused!");
        _safeMint(_address, _mintAmount);
        
    }

    function freemint(
        uint256 _mintAmount,
        uint256 _timestamp,
        bytes memory _signature
    ) public nonReentrant {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= freemint_supply,
            "Freemint Max supply exceeded!"
        );
        require(!paused, "The contract is paused!");
        // require(msg.value >= cost * _mintAmount, "Insufficient funds!");

        address wallet = _msgSender();
        if (isSignature) {
            address signerOwner = signatureWallet(
                wallet,
                _mintAmount,
                _timestamp,
                _signature
            );
            require(signerOwner == owner(), "Not authorized to mint");

            require(block.timestamp >= _timestamp - 30, "Out of time");

            _safeMint(wallet, _mintAmount);
        } else {
            _safeMint(wallet, _mintAmount);
        }
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        onlyOwner
    {
        _safeMint(_receiver, _mintAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setFreemintSupply(uint256 _freemintSupply) public onlyOwner {
        freemint_supply = _freemintSupply;
    }

    function withdrawAll(address _withdrawAddress) public onlyOwner {
        (bool os, ) = payable(_withdrawAddress).call{
            value: address(this).balance
        }("");
        require(os);
    }

    function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

    // METADATA HANDLING

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setBaseURI(string calldata baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "URI does not exist!");

        if (revealed) {
            return
                string(
                    abi.encodePacked(_baseURI(), _tokenId.toString(), ".json")
                );
        } else {
            return
                string(
                    abi.encodePacked(hiddenMetadataUri, _tokenId.toString(), ".json")
                );
        }
    }

    function Airdrop() private{
        freeMintAirdrop(0xE5BaDEa71d2ad9d284f80a3cb91231997a5d74a4, 2);
        freeMintAirdrop(0xE7C26A45dC27b7BE98d265F4D86D4859f4147cca, 2);
        freeMintAirdrop(0xa978291BDfeeaC037Aa8141FEF2BB7e9c511D659, 8);
        freeMintAirdrop(0x750E19B430dfF7Fc16fEe27aA97A5D0a030D57A4, 8);
        freeMintAirdrop(0x444458e24a60560DE3A9aF2fe59cc7a695ca1821, 8);
        freeMintAirdrop(0x90c0F855979018daBC6b517f39FAddc90Acae292, 4);
        freeMintAirdrop(0xCEA7225621e68aD823EdC4AcaB399C640E1cE89A, 6);
        freeMintAirdrop(0xf67b32F542D461D4960dDC01A773684D44cFFa20, 2);
        freeMintAirdrop(0x29f9ef8286dcc4F9a94340278DB01f12c3483988, 2);
        freeMintAirdrop(0x3bb5A706AE90ba7ea5a7403b20A134b6D8c6B815, 2);
        freeMintAirdrop(0x3Dc954502511Ed10735FDd0c2189fe7E0730Bf4C, 2);
        freeMintAirdrop(0xb130923C16796Da5A96B87529d77B1dbdF4C1E79, 4);
        freeMintAirdrop(0xC13e5551C962Ea93B2Fb4b4F42ECDbA5CBA50c63, 2);
        freeMintAirdrop(0xbb7E5320AFe5F90fF1912Fcec1fCA60061711b9f, 4);
        freeMintAirdrop(0xd068bCb3F588431C32e84345ceEe045C409C1e23, 2);
        freeMintAirdrop(0xa48F47A3641f37116B816cF571bd5a4bbf456BaD, 2);
        freeMintAirdrop(0xDb4d6FbE29215F8B430C404958c8CE1581D4Ca98, 2);
        freeMintAirdrop(0x536908A363132bCa6dB5C3B4F4eadb4C768f93dC, 2);
        freeMintAirdrop(0x493827DF59A3077b46215f22512204D374b2Cd5E, 4);
        freeMintAirdrop(0xb130923C16796Da5A96B87529d77B1dbdF4C1E79, 10);
        freeMintAirdrop(0x5DFDE2228e0971C4f10A8379e1fbAd7F30D699Fe, 5);
        freeMintAirdrop(0x0D189f7E6e0c38f908422169423134efa8feb110, 2);
        freeMintAirdrop(0xEB243A2F3eFE1AfC1ACF2aa371b8B12DBD90B925, 2);
        freeMintAirdrop(0xDAcf8123C912098Dc6b3248Ede8cBaeEADe8666c, 5);
        freeMintAirdrop(0xb130923C16796Da5A96B87529d77B1dbdF4C1E79, 10);
        freeMintAirdrop(0x1eb627488314501cB7C1964923c5e9B619B0aa13, 11);
        freeMintAirdrop(0xc56A7B098aAc17ae2DE38045316E94Ace6660F07, 15);
        freeMintAirdrop(0xDb4d6FbE29215F8B430C404958c8CE1581D4Ca98, 11);
        freeMintAirdrop(0xec4d2F96B00E7C9eD0dAD95F614B4a22730Bfc88, 11);
        freeMintAirdrop(0x73dD7e2209A3A7D530B6A2572FDBA9Aa72d1A3f8, 5);
        freeMintAirdrop(0x3b7cf36B6BeACA538BEf989a9DDE239189fDBD26, 3);
        freeMintAirdrop(0x469461E43000CacDF7A93edfACf20Ad40bb067Ba, 5);
        freeMintAirdrop(0x0Ee2d68A4ebfFCcD9746FF90698aa44607e41173, 5);
        freeMintAirdrop(0xfce76f34A5b136c6FCAdb1aBd66ccF2F5d9C250C, 5);
        freeMintAirdrop(0x7A47028766Ab9B37D7B176EE5df24050bdC7e730, 5);
        freeMintAirdrop(0x71A10EB29db3a9B30dF9cDbE76480F37c59649c9, 5);
        freeMintAirdrop(0x90c874351097645b413B362871F220D0c0952d9D, 5);
        freeMintAirdrop(0x961CDf0A4483181be500724aB052E8DcbAc75B15, 5);
        freeMintAirdrop(0xc31e659368bA22826c2230F56C26F00897CDe76C, 10);
        freeMintAirdrop(0x961CDf0A4483181be500724aB052E8DcbAc75B15, 5);
        freeMintAirdrop(0xeF1A70Eb3f1Eb4ED406fAddfa6Ff7547510B7024, 5);
        freeMintAirdrop(0x6C8F712530D75f114cA4dc8b076ed6c4ADd79D7e, 5);
        freeMintAirdrop(0x8BB900A63D240F6B8f9aC3C1432760b1C2e79710, 3);
        freeMintAirdrop(0xe135e0B283cc9470bE938Cbe01101275Ec243274, 3);
        freeMintAirdrop(0x07Fab93C4b03A5E46Fb7AF6Ab5Ad0C30e78702E0, 3);
        freeMintAirdrop(0x619a7a24E94643d6b22a2d43A05063d3cC2507AD, 5);
        freeMintAirdrop(0x0645e6121E034619A808644fB2487Acf5DE81e20, 5);
        freeMintAirdrop(0x640eEec18ad93c629a02e244028E8B6C9357167f, 200);
    }
}