// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

    /***
     *    ::::    ::: :::::::::: :::       ::: ::::    ::::      :::     ::::    ::: ::::    ::: :::::::::: ::::::::::: ::::::::
     *    :+:+:   :+: :+:        :+:       :+: +:+:+: :+:+:+   :+: :+:   :+:+:   :+: :+:+:   :+: :+:            :+:    :+:    :+:
     *    :+:+:+  +:+ +:+        +:+       +:+ +:+ +:+:+ +:+  +:+   +:+  :+:+:+  +:+ :+:+:+  +:+ +:+            +:+    +:+
     *    +#+ +:+ +#+ +#++:++#   +#+  +:+  +#+ +#+  +:+  +#+ +#++:++#++: +#+ +:+ +#+ +#+ +:+ +#+ :#::+::#       +#+    +#++:++#++
     *    +#+  +#+#+# +#+        +#+ +#+#+ +#+ +#+       +#+ +#+     +#+ +#+  +#+#+# +#+  +#+#+# +#+            +#+           +#+
     *    #+#   #+#+# #+#         #+#+# #+#+#  #+#       #+# #+#     #+# #+#   #+#+# #+#   #+#+# #+#            #+#    #+#    #+#
     *    ###    #### ##########   ###   ###   ###       ### ###     ### ###    #### ###    #### ###            ###     ########
     *
     *************************************************************************
     * @author: @ghooost0x2a                                                  *
     *************************************************************************
     * NewmanNFTB2FA is based on ERC721B low gas contract by @squuebo_nft    *
     * and the LockRegistry/Guardian contracts by @OwlOfMoistness            *
     *************************************************************************
     *     :::::::              ::::::::      :::                            *
     *    :+:   :+: :+:    :+: :+:    :+:   :+: :+:                          *
     *    +:+  :+:+  +:+  +:+        +:+   +:+   +:+                         *
     *    +#+ + +:+   +#++:+       +#+    +#++:++#++:                        *
     *    +#+#  +#+  +#+  +#+    +#+      +#+     +#+                        *
     *    #+#   #+# #+#    #+#  #+#       #+#     #+#                        *
     *     #######             ########## ###     ###                        *
     *************************************************************************/

import "./ERC721EnumerableLiteB2FA.sol";
import "./GuardianLiteB2FA.sol";
import "./MerkleProof.sol";
import "./ERC721Pausable.sol";
import "./Address.sol";
import "./Strings.sol";

contract NewmanNFTB2FA is ERC721EnumerableLiteB2FA, GuardianLiteB2FA, Pausable {
    using MerkleProof for bytes32[];
    using Address for address;
    using Strings for uint256;

    event Withdrawn(address indexed payee, uint256 weiAmount);

    uint256 public constant MAX_SUPPLY = 777;
    uint256 public publicPrice = 0.07 ether;
    uint256 public reducedPrice = 0.03 ether;
    uint256 public maxMintsPerTx = 5;

    address public communityWallet = 0x4A234b2Cbbe4053360397db002190732AB149A9a;
    //0x4Ab83CE58A2D83BD5b182019aAF261245E467422;
    string private baseURI = "ipfs://QmS6wss82sHCZsJ3jEn3t6oUYjz384juEyxjG7D4vThNdf/";
    string private uriSuffix = ".json";
    string private commonURI = "";
    bytes32 private merkleRoot = 0;
    address[] internal reducedPriceMinted;

    fallback() external payable {
        revert("You hit the fallback fn, fam! Try again.");
    }

    receive() external payable {
        revert("I love ETH, but don't send it to this contract!");
    }

    constructor() ERC721EnumerableLiteB2FA("NewmanNFT", "NEW", 1) {}

    function getMerkleRoot() public view onlyDelegates returns (bytes32) {
        return merkleRoot;
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
        //require(proof_valid, "Address not in Merkle Tree"); // dev: NOPE! No Merkle Tree for you
        return proof_valid;
    }

    function togglePause(uint256 pauseit) external onlyDelegates {
        if (pauseit == 0) {
            _unpause();
        } else {
            _pause();
        }
    }

    function getReducedPriceMinted()
        external
        view
        onlyDelegates
        returns (address[] memory)
    {
        return reducedPriceMinted;
    }

    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        ); // dev: Sorry homie, that token doesn't exist

        if (bytes(commonURI).length > 0) {
            return string(abi.encodePacked(commonURI));
        }

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, tokenId.toString(), uriSuffix)
                )
                : "";
    }

    function setPublicPrice(uint256 newPrice) external onlyDelegates {
        publicPrice = newPrice;
    }

    function setReducedPrice(uint256 newPrice) external onlyDelegates {
        reducedPrice = newPrice;
    }

    function setMaxMintsPerTx(uint256 maxMint) external onlyDelegates {
        maxMintsPerTx = maxMint;
    }

    function setCommunityWallet(address newCommunityWallet) external onlyOwner {
        communityWallet = newCommunityWallet;
    }

    function setMerkleRoot(bytes32 root) external onlyDelegates {
        merkleRoot = root;
    }

    function setCommonURI(string calldata newCommonURI) external onlyDelegates {
        commonURI = newCommonURI;
    }

    function setBaseURI(
        string calldata newBaseURI,
        string calldata newURISuffix
    ) external onlyDelegates {
        baseURI = newBaseURI;
        uriSuffix = newURISuffix;
    }

    function freeMints(uint256 quantity, address[] calldata recipients)
        external
        onlyDelegates
    {
        minty(quantity, recipients);
    }

    function publicMints(
        uint256 quantity,
        address[] calldata recipients,
        bytes32[] memory proof
    ) external payable {
        require(quantity <= maxMintsPerTx, "You can't mint that many at once!");
        uint256 price = publicPrice;
        if (isvalidMerkleProof(proof)) {
            require(quantity == 1, "You can only mint 1 NFT at discount.");
            for (uint256 i; i < reducedPriceMinted.length; i++) {
                if (reducedPriceMinted[i] == msg.sender) {
                    revert("This address already minted at a discount!");
                }
            }
            reducedPriceMinted.push(msg.sender);
            price = reducedPrice;
        } else {
            require(!paused(), "Public Mint is paused!");
        }

        require(msg.value == price * quantity, "Incorrect amount of ETH sent!");
        minty(quantity, recipients);
    }

    function minty(uint256 quantity, address[] calldata recipients) internal {
        require(quantity > 0, "Can't mint 0 tokens!");
        require(
            quantity == recipients.length || recipients.length == 1,
            "Call data is invalid"
        ); // dev: Call parameters are no bueno
        uint256 totSup = totalSupply();
        require(quantity + totSup <= MAX_SUPPLY, "Max supply reached!");

        address mintTo = communityWallet;
        for (uint256 i; i < quantity; ++i) {
            mintTo = recipients.length == 1 ? recipients[0] : recipients[i];
            _mint(mintTo, totSup + i + _offset);
        }
    }

    function withdraw() external onlyDelegates {
        uint256 payment = address(this).balance;
        address payable addy = payable(communityWallet);
        (bool success, ) = addy.call{value: payment}("");
        require(success, "Withdrawal failed!");
        emit Withdrawn(communityWallet, payment);
    }
}
