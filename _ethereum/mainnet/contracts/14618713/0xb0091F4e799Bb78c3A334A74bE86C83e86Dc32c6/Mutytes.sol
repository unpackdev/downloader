// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

/**
 * ################################################################################
 * ################################################################################
 * ################################################################################
 * ################################################################################
 * ################################################################################
 * #######################################   ######################################
 * #####################################       ####################################
 * ###################################           ##################################
 * #################################               ################################
 * ################################################################################
 * ################################################################################
 * ################       ####                           ###        ###############
 * ################      ####        #############        ####      ###############
 * ################     ####          ###########          ####     ###############
 * ################    ###     ##       #######       ##    ####    ###############
 * ################  ####    ######      #####      ######    ####  ###############
 * ################ ####                                       #### ###############
 * ####################                #########                ###################
 * ################                     #######                     ###############
 * ################   ###############             ##############   ################
 * #################   #############               ############   #################
 * ###################   ##########                 ##########   ##################
 * ####################    #######                   #######    ###################
 * ######################     ###                     ###    ######################
 * ##########################                             #########################
 * #############################                       ############################
 * ################################################################################
 * ################################################################################
 * ################################################################################
 * ################################################################################
 * ################################################################################
 * ################################################################################
 *
 * The Mutytes have invaded Ethernia! We hereby extend access to the lab and
 * its facilities to any individual or party that may locate and retrieve a
 * Mutyte sample. We believe their mutated Bit Signatures hold the key to
 * unraveling many great mysteries.
 * Join our efforts in understanding these creatures and witness Ethernia's
 * future unfold.
 *
 * Founders: @nftyte & @tuyumoo
 */

import "./ERC721GeneticData.sol";
import "./Reservable.sol";
import "./ProxyOperated.sol";
import "./IERC721Metadata.sol";
import "./IMutationInterpreter.sol";

interface ILabArchive {
    function getMutyteInfo(uint256 tokenId)
        external
        view
        returns (string memory name, string memory info);

    function getMutationInfo(uint256 mutationId)
        external
        view
        returns (string memory name, string memory info);
}

interface IBineticSplicer {
    function getSplices(uint256 tokenId)
        external
        view
        returns (uint256[] memory);
}

contract Mutytes is
    ERC721GeneticData,
    IERC721Metadata,
    Reservable,
    ProxyOperated
{
    string constant NAME = "Mutytes";
    string constant SYMBOL = "TYTE";
    uint256 constant MINT_PER_ADDR = 10;
    uint256 constant MINT_PER_ADDR_EQ = MINT_PER_ADDR + 1; // Skip the equator
    uint256 constant MINT_PRICE = 0.1 ether;

    address public labArchiveAddress;
    address public bineticSplicerAddress;
    string public externalURL;

    constructor(
        string memory externalURL_,
        address interpreter,
        address proxyRegistry,
        uint8 reserved
    )
        Reservable(reserved)
        ProxyOperated(proxyRegistry)
        MutationRegistry(interpreter)
    {
        externalURL = externalURL_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function mint(uint256 count) external payable {
        uint256 id = maxSupply;

        require(id > 0, "Mutytes: public mint not open");

        require(
            id + count < MAX_SUPPLY_EQ - reserved,
            "Mutytes: amount exceeds available supply"
        );

        require(
            count > 0 && _getBalance(_msgSender()) + count < MINT_PER_ADDR_EQ,
            "Mutytes: invalid token count"
        );

        require(
            msg.value == count * MINT_PRICE,
            "Mutytes: incorrect amount of ether sent"
        );

        _mint(_msgSender(), id, count);
    }

    function mintReserved(uint256 count) external fromAllowance(count) {
        _mint(_msgSender(), maxSupply, count);
    }

    function setLabArchiveAddress(address archive) external onlyOwner {
        labArchiveAddress = archive;
    }

    function setBineticSplicerAddress(address splicer) external onlyOwner {
        bineticSplicerAddress = splicer;
    }

    function setExternalURL(string calldata url) external onlyOwner {
        externalURL = url;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public pure override returns (string memory) {
        return NAME;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public pure override returns (string memory) {
        return SYMBOL;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        tokenExists(tokenId)
        returns (string memory)
    {
        uint256 mutationId = getTokenMutation(tokenId);
        IMutationInterpreter interpreter = IMutationInterpreter(
            getMutation(mutationId).interpreter
        );
        IMutationInterpreter.TokenData memory token;
        token.id = tokenId;
        IMutationInterpreter.MutationData memory mutation;
        mutation.id = mutationId;
        mutation.count = _countTokenMutations(tokenId);

        if (bineticSplicerAddress != address(0)) {
            IBineticSplicer splicer = IBineticSplicer(bineticSplicerAddress);
            token.dna = getTokenDNA(tokenId, splicer.getSplices(tokenId));
        } else {
            token.dna = getTokenDNA(tokenId);
        }

        if (labArchiveAddress != address(0)) {
            ILabArchive archive = ILabArchive(labArchiveAddress);
            (token.name, token.info) = archive.getMutyteInfo(tokenId);
            (mutation.name, mutation.info) = archive.getMutationInfo(
                mutationId
            );
        }

        return interpreter.tokenURI(token, mutation, externalURL);
    }

    function burn(uint256 tokenId) public onlyApprovedOrOwner(tokenId) {
        _burn(tokenId);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override(ERC721Enumerable, IERC721)
        returns (bool)
    {
        return
            _isProxyApprovedForAll(owner, operator) ||
            super.isApprovedForAll(owner, operator);
    }

    function withdraw() public payable onlyOwner {
        (bool owner, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(owner, "Mutytes: withdrawal failed");
    }

    function _mint(
        address to,
        uint256 tokenId,
        uint256 count
    ) private {
        uint256 inventory = _getOrSubscribeInventory(to);
        bytes32 dna;

        unchecked {
            uint256 max = tokenId + count;
            while (tokenId < max) {
                if (dna == 0) {
                    dna = keccak256(
                        abi.encodePacked(
                            tokenId,
                            inventory,
                            block.number,
                            block.difficulty,
                            reserved
                        )
                    );
                }
                _tokenToInventory[tokenId] = uint16(inventory);
                _tokenBaseGenes[tokenId] = uint64(bytes8(dna));
                dna <<= 64;

                emit Transfer(address(0), to, tokenId++);
            }
        }

        _increaseBalance(to, count);
        maxSupply = tokenId;
    }
}
