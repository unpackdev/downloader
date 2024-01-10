// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC721A.sol";
import "./Ownable.sol";

interface IPup {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;
}

contract PupFrens is ERC721A, Ownable {
    string private _name = "PupFrens";
    string private _symbol = "PFP";
    uint256 public MAX_MINT_PER_TX = 20;

    IPup public pupContract;

    string private _customBaseUri = "https://assets.pupfrens.com/metadata/";
    string private _contractUri =
        "https://assets.pupfrens.com/metadata/contract.json";

    uint256 public maxSupply = 10000;

    uint256 public priceEthWei = 99999 ether;
    uint256 public priceMilliPup = 50000000000; // 50 million $PUP starting price (50m + 3 decimals)

    event MintedWithPup(uint256 numMinted, uint256 priceMilliPup);

    event MintedWithEth(uint256 numMinted, uint256 priceEthWei);

    constructor() public ERC721A(_name, _symbol) {
        pupContract = IPup(_pupErc20Address());
    }

    function mintWithPup(uint256 numToMint) public {
        _checkMintAmount(numToMint);
        uint256 totalMilliPup = numToMint * priceMilliPup;
        // Transfering the PUP to this contract's address effectively burns the PUP because it cannot be withdrawn from here.
        pupContract.transferFrom(msg.sender, address(this), totalMilliPup);
        _safeMint(msg.sender, numToMint);
        emit MintedWithPup(numToMint, priceMilliPup);
    }

    function mintWithEth(uint256 numToMint) public payable {
        _checkMintAmount(numToMint);
        _checkEthPayment(numToMint);
        _safeMint(msg.sender, numToMint);
        emit MintedWithEth(numToMint, priceEthWei);
    }

    function _checkMintAmount(uint256 numToMint) internal view {
        require(
            numToMint <= MAX_MINT_PER_TX,
            "Trying to mint too many in a single tx"
        );
        require(
            totalSupply() + numToMint <= maxSupply,
            "minting would exceed max supply"
        );
    }

    function _checkEthPayment(uint256 numMinted) internal view {
        uint256 amountRequired = priceEthWei * numMinted;
        require(msg.value >= amountRequired, "Not enough funds sent");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _customBaseUri;
    }

    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    /**
     * Gets the contract address for the PUP erc20 token.
     */
    function _pupErc20Address() internal view returns (address) {
        address addr;
        assembly {
            switch chainid()
            case 1 {
                // mainnet
                addr := 0x2696Fc1896F2D5F3DEAA2D91338B1D2E5f4E1D44
            }
            case 4 {
                // rinkeby
                addr := 0x183B665119F1289dFD446a2ebA29f858eE0D3224
            }
        }
        return addr;
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return
            OpenSeaGasFreeListing.isApprovedForAll(owner, operator) ||
            super.isApprovedForAll(owner, operator);
    }

    function setEthWeiPrice(uint256 newPriceWei) public onlyOwner {
        priceEthWei = newPriceWei;
    }

    function setMilliPupPrice(uint256 newPriceMilliPup) public onlyOwner {
        priceMilliPup = newPriceMilliPup;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setBaseURI(string calldata newURI) public onlyOwner {
        _customBaseUri = newURI;
    }

    function setContractUri(string calldata newUri) public onlyOwner {
        _contractUri = newUri;
    }

    function decreaseMaxSupply(uint256 newSupply) public onlyOwner {
        require(newSupply < maxSupply);
        maxSupply = newSupply;
    }
}

library OpenSeaGasFreeListing {
    /**
    @notice Returns whether the operator is an OpenSea proxy for the owner, thus
    allowing it to list without the token owner paying gas.
    @dev ERC{721,1155}.isApprovedForAll should be overriden to also check if
    this function returns true.
     */
    function isApprovedForAll(address owner, address operator)
        internal
        view
        returns (bool)
    {
        ProxyRegistry registry;
        assembly {
            switch chainid()
            case 1 {
                // mainnet
                registry := 0xa5409ec958c83c3f309868babaca7c86dcb077c1
            }
            case 4 {
                // rinkeby
                registry := 0xf57b2c51ded3a29e6891aba85459d600256cf317
            }
        }

        return
            address(registry) != address(0) &&
            address(registry.proxies(owner)) == operator;
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
