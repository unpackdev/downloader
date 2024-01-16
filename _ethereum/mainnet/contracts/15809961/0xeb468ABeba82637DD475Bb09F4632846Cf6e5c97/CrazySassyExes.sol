// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/*
 *
 *       d888888o.           .8.            d888888o.      d888888o.  `8.`8888.      ,8'
 *     .`8888:' `88.        .888.         .`8888:' `88.  .`8888:' `88. `8.`8888.    ,8'
 *     8.`8888.   Y8       :88888.        8.`8888.   Y8  8.`8888.   Y8  `8.`8888.  ,8'
 *     `8.`8888.          . `88888.       `8.`8888.      `8.`8888.       `8.`8888.,8'
 *      `8.`8888.        .8. `88888.       `8.`8888.      `8.`8888.       `8.`88888'
 *       `8.`8888.      .8`8. `88888.       `8.`8888.      `8.`8888.       `8. 8888
 *        `8.`8888.    .8' `8. `88888.       `8.`8888.      `8.`8888.       `8 8888
 *    8b   `8.`8888.  .8'   `8. `88888.  8b   `8.`8888. 8b   `8.`8888.       8 8888
 *    `8b.  ;8.`8888 .888888888. `88888. `8b.  ;8.`8888 `8b.  ;8.`8888       8 8888
 *     `Y8888P ,88P'.8'       `8. `88888. `Y8888P ,88P'  `Y8888P ,88P'       8 8888
 *
 * FOUNDER: @StudioIrida
 * ART: @StudioIrida
 * DEV: @ghooost0x2a
 **********************************
 * @title: Crazy Sassy Exes
 * @author: @ghooost0x2a
 **********************************
 * ERC721B2FA - Ultra Low Gas - 2 Factor Authentication
 *****************************************************************
 * ERC721B2FA is based on ERC721B low gas contract by @squuebo_nft
 * and the LockRegistry/Guardian contracts by @OwlOfMoistness
 *****************************************************************
 *      .-----.
 *    .' -   - '.
 *   /  .-. .-.  \
 *   |  | | | |  |
 *    \ \o/ \o/ /
 *   _/    ^    \_
 *  | \  '---'  / |
 *  / /`--. .--`\ \
 * / /'---` `---'\ \
 * '.__.       .__.'
 *     `|     |`
 *      |     \
 *      \      '--.
 *       '.        `\
 *         `'---.   |
 *            ,__) /
 *             `..'
 */

import "./ERC721B2FAEnumLitePausable.sol";
import "./GuardianLiteB2FA.sol";
import "./MerkleProof.sol";
import "./Address.sol";
import "./Strings.sol";

contract CrazySassyExes is ERC721B2FAEnumLitePausable, GuardianLiteB2FA {
    using MerkleProof for bytes32[];
    using Address for address;
    using Strings for uint256;

    event Withdrawn(address indexed payee, uint256 weiAmount);

    uint256 public MAX_SUPPLY = 3333;

    uint256 public publicPrice = 0.025 ether;
    uint256 public publicPriceDiscounted = 0.02 ether;
    uint256 public preSalePrice = 0.015 ether;
    uint256 public preSalePriceDiscounted = 0.01 ether;

    string internal baseURI = "";
    string internal uriSuffix = ".json";

    address public paymentRecipient =
        0xA94F799A34887582987eC8C050f080e252B70A21;

    // dev: public mints
    uint256 public maxPublicCSEMintsPerWallet = 3;
    uint256 public maxPreSaleCSEMintsPerWallet = 3;

    bytes32 private merkleRoot = 0;
    mapping(address => uint256) public presaleMintedAddys;
    mapping(address => uint256) public publicMintedAddys;

    uint256 public mintPhase = 0;

    //TODO STRUCT FOR STATUS            

    constructor() ERC721B2FAEnumLitePausable("CrazySassyExes", "CSE", 1) {}

    fallback() external payable {}

    receive() external payable {}

    function setMintPhase(uint256 newPhase) external onlyDelegates {
        mintPhase = newPhase;
    }

    function tokenURI(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, tokenId.toString(), uriSuffix)
                )
                : "";
    }

    //setter fns
    function togglePause(uint256 pauseIt) external onlyDelegates {
        if (pauseIt == 0) {
            _unpause();
        } else {
            _pause();
        }
    }

    function getMerkleRoot() public view returns (bytes32) {
        return merkleRoot;
    }

    function setMerkleRoot(bytes32 mRoot) external onlyDelegates {
        merkleRoot = mRoot;
    }

    function updateBlackListedApprovals(address[] calldata addys, bool[] calldata blacklisted) external onlyDelegates{
        require(addys.length == blacklisted.length, "Nb addys doesn't match nb bools.");
        for (uint256 i; i < addys.length; ++i) {
            _updateBlackListedApprovals(addys[i], blacklisted[i]);
        }
    }    

    function isvalidMerkleProof(bytes32[] memory proof)
        public
        view
        returns (bool)
    {
        if (merkleRoot == 0) {
            return false;
        }
        bool proof_valid = proof.verify(
            merkleRoot,
            keccak256(abi.encodePacked(msg.sender))
        );
        return proof_valid;
    }    

    function setPublicPrice(uint256 newPrice, uint256 newDiscountedPrice) external onlyDelegates {
        publicPrice = newPrice;
        publicPriceDiscounted = newDiscountedPrice;
    }

    function setPreSalePrice(uint256 newPrice, uint256 newDiscountedPrice) external onlyDelegates {
        preSalePrice = newPrice;
        preSalePriceDiscounted = newDiscountedPrice;
    }

    function setBaseSuffixURI(
        string calldata newBaseURI,
        string calldata newURISuffix
    ) external onlyDelegates {
        baseURI = newBaseURI;
        uriSuffix = newURISuffix;
    }

    function setmaxCSEMintsPerWallet(uint256 maxPresaleMints, uint256 maxPublicMints) external onlyDelegates {
        maxPublicCSEMintsPerWallet = maxPublicMints;
        maxPreSaleCSEMintsPerWallet = maxPresaleMints;
    }

    function setPaymentRecipient(address addy) external onlyDelegates {
        paymentRecipient = addy;
    }

    function setReducedMaxSupply(uint256 new_max_supply)
        external
        onlyDelegates
    {
        require(new_max_supply < MAX_SUPPLY, "Can only set a lower size.");
        require(
            new_max_supply >= totalSupply(),
            "New supply lower than current totalSupply"
        );
        MAX_SUPPLY = new_max_supply;
    }

    // Mint fns
    function freeTeamMints(uint256 quantity, address[] memory recipients)
        external
        onlyDelegates
    {
        if (recipients.length == 1) {
            for (uint256 i = 0; i < quantity; i++) {
                _minty(1, recipients[0]);
            }
        }
        else {
            require(quantity == recipients.length, "Number of recipients doesn't match quantity.");
            for (uint256 i = 0; i < recipients.length; i++) {
                _minty(1, recipients[i]);
            }            
        }
    }

    // Pre-sale mint
    function sassyMint(uint256 quantity, bytes32[] memory proof) external payable {
        uint256 total_mint_price = preSalePrice;
        if (quantity > 1) {
            total_mint_price = quantity * preSalePriceDiscounted;
        }        
        require(
            mintPhase == 1 || _isDelegate(_msgSender()),
            "Pre-Sale mint not open"
        );
        require(msg.value == total_mint_price, "Wrong amount of ETH sent!");
        require(
            presaleMintedAddys[_msgSender()] + quantity <= maxPreSaleCSEMintsPerWallet,
            "Already minted max during pre-sale."
        );
        require(
            isvalidMerkleProof(proof),
            "You are not authorized for pre-sale."
        );

        presaleMintedAddys[_msgSender()] += quantity;
        _minty(quantity, _msgSender());
    }

    // Public Mint
    function publicMint(uint256 quantity) external payable {
        uint256 total_mint_price = publicPrice;
        if (quantity > 1) {
            total_mint_price = quantity * publicPriceDiscounted;
        }
        require(
            mintPhase == 2 || _isDelegate(_msgSender()),
            "Public mint is not open yet!"
        );
        require(msg.value == total_mint_price, "Wrong amount of ETH sent!");
        require(
            publicMintedAddys[_msgSender()] + quantity <=
                maxPublicCSEMintsPerWallet,
            "You have minted max during public phase."
        );
        publicMintedAddys[_msgSender()] += quantity;
        _minty(quantity, _msgSender());
    }

    function _minty(uint256 quantity, address addy) internal {
        require(quantity > 0, "Can't mint 0 tokens!");
        require(quantity + totalSupply() <= MAX_SUPPLY, "Max supply reached!");
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(addy, next());
        }
    }    

    //Just in case some ETH ends up in the contract so it doesn't remain stuck.
    function withdraw() external onlyDelegates {
        uint256 contract_balance = address(this).balance;

        address payable w_addy = payable(paymentRecipient);

        (bool success, ) = w_addy.call{value: (contract_balance)}("");
        require(success, "Withdrawal failed!");

        emit Withdrawn(w_addy, contract_balance);
    }
}
