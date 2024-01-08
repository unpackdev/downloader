//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.3;

import "./ERC721.sol";
import "./IERC20.sol";
import "./PSI.sol";

contract DeepGems is ERC721 {
    constructor(address psiContract, string memory baseURI)
        ERC721("Deep Gems", "DEEP")
    {
        PSI_CONTRACT = psiContract;
        BASE_URI = baseURI;
    }

    address public PSI_CONTRACT;
    string BASE_URI;

    uint120 public state_counter;
    mapping(uint256 => address) public state_unactivatedGems;

    event Forged(uint256 indexed tokenId);
    event Reforged(uint256 indexed oldTokenId, uint256 indexed newTokenId);
    event Activated(uint256 indexed tokenId);
    event Burned(uint256 indexed tokenId);

    function packTokenId(uint128 a, uint128 b) internal pure returns (uint256) {
        return (uint256(a) << 128) | b;
    }

    function unpackTokenId(uint256 a) internal pure returns (uint128, uint128) {
        return (uint128(a >> 128), uint128(a));
    }

    function counterFromTokenId(uint256 tokenId) public pure returns (uint120) {
        return uint120(tokenId >> 136);
    }

    function extractPsiFromOldGem(uint256 tokenId) internal returns (uint128) {
        // 5% (1/20th) of the psi is burned
        uint128 oldPsi = uint128(tokenId);
        uint128 burnedPsi = oldPsi / 20;
        PSI(PSI_CONTRACT).burn(burnedPsi);

        return oldPsi - burnedPsi;
    }

    function blockHashEntropy() internal view returns (uint8) {
        // We add in entropy from two blocks to make things more random. A miner who
        // finds blockhash(block.number - 1) will have increased their search space
        // for identical gems by 4 bits. A miner who finds blockhash(block.number - 255)
        // will have increased their search space by the same amount, but only if nobody else
        // forges a gem in the following 255 blocks, because that will throw off their calculations.

        // We left shift a by 4, adding 4 zero bits onto the end.
        // Then we right shift b by 4, moving the first 4 bits to the end and making the rest 0.
        // Then we XOR them, effectively creating a byte with the last 4 bits of a and the first 4 bits of b
        // a << 4:  |11111111| -> |11110000|
        // b >> 4:  |11111111| -> |00001111|
        // a | b:                 |11111111|
        return
            (uint8(uint256(blockhash(block.number - 1))) << 4) |
            (uint8(uint256(blockhash(block.number - 255))) >> 4);
    }

    function packSeed(uint120 counter, uint8 blockhashEntropy)
        internal
        pure
        returns (uint128)
    {
        return (uint128(counter) << 8) | blockhashEntropy;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function _forge(uint256 amountPsi) internal returns (uint256) {
        require(
            amountPsi >= 0.1 ether,
            "gems must be forged with at least 0.1 PSI"
        );

        state_counter = state_counter + 1;

        // Generate tokenId. The tokenId contains the gem's seed, and the amount of PSI
        // it was forged with
        uint256 tokenId =
            packTokenId(
                packSeed(
                    // Deep gems uses a combination of entropy from the counter and
                    // two block hashes to determine the seed of a gem.
                    // This is OK, because there is no objective rarity or lottery-like mechanic in Deep gems.
                    // The value of each gem is based on how attractive people find it.
                    // The only attack possible is one where someone searches for a latent vector that
                    // produces a gem indistinguishable from one that has already been forged. To be able to search at all,
                    // you would have to mine 2 blocks, 255 blocks apart, and accurately predict where the counter
                    // would be. You would then have 8 bits of search space. To manipulate the counter, you would need
                    // to spend 0.1 PSI for each increment, since this is the minimum forge amount.
                    state_counter,
                    blockHashEntropy()
                ),
                uint128(amountPsi)
            );

        return tokenId;
    }

    function forge(uint256 amountPsi) public returns (uint256) {
        // Transfer Psi to pay for gem
        PSI(PSI_CONTRACT).transferToDeepGems(msg.sender, amountPsi);

        uint256 tokenId = _forge(amountPsi);

        // Add gem to unactivated gems mapping
        state_unactivatedGems[tokenId] = msg.sender;

        emit Forged(tokenId);

        return tokenId;
    }

    function reforge(uint256 oldtokenId) public returns (uint256) {
        require(
            state_unactivatedGems[oldtokenId] == msg.sender,
            "gem is already activated, you don't own it, or it does not exist"
        );

        delete state_unactivatedGems[oldtokenId];

        // Add psi into new tokenId, minus 5%
        uint256 newTokenId = _forge(extractPsiFromOldGem(oldtokenId));

        // Add gem to unactivated gems mapping
        state_unactivatedGems[newTokenId] = msg.sender;

        emit Reforged(oldtokenId, newTokenId);

        return newTokenId;
    }

    function activate(uint256 tokenId) public {
        require(
            state_unactivatedGems[tokenId] == msg.sender,
            "gem is already activated, you don't own it, or it does not exist"
        );

        delete state_unactivatedGems[tokenId];

        _mint(msg.sender, tokenId);
        emit Activated(tokenId);
    }

    function burn(uint256 tokenId) public {
        if (state_unactivatedGems[tokenId] == msg.sender) {
            // We are burning an unactivated gem
            delete state_unactivatedGems[tokenId];
        } else if (_exists(tokenId) && ownerOf(tokenId) == msg.sender) {
            // We are burning an activated gem
            _burn(tokenId);
        } else {
            revert("this gem does not exist or you don't own it");
        }

        // Transfer the psi in the gem to the caller, minus 5 percent
        IERC20(PSI_CONTRACT).transfer(
            msg.sender,
            uint256(extractPsiFromOldGem(tokenId))
        );

        emit Burned(tokenId);
    }

    function getGemMetadata(uint256 tokenId)
        public
        pure
        returns (
            uint32,
            uint32,
            uint32,
            uint32,
            uint32
        )
    {
        (uint128 latent, uint128 psi) = unpackTokenId(tokenId);
        // We want 100 psi to correspond to an input of 1 into truncation_psi in the neural net,
        // and 103 psi to correspond to 1.03 truncation_psi, etc.
        // So we scale by 1e18, which results in e.g. 103 PSI = 103 (losing 18 decimal places).
        // Before putting it into the neural net, we will divide by 100, giving us a truncation_psi of 1.03 for this example.
        uint32 scaledPsi = uint32(psi / 1e18);

        // We will pass the uint128 latent into the gan as an array of 4 u32's. It's easiest format it here.
        // The psi goes on the end. Since we scaled it, it easily fits into a uint32.
        return (
            uint32(latent >> 96),
            uint32(latent >> 64),
            uint32(latent >> 32),
            uint32(latent),
            scaledPsi
        );
    }
}
