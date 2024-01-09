
// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;


import "./CoreGuild.sol";


// Guild Genesis Calculation
// Can be any time in the past, we choose block 1 because it gives a reasonable number of cheap expeditions.
//
// ~ 1 years ago
// (block.timestamp - (60*60*24*365))
//
// Block 1
// 1438269988

// Guild Rate Calculation
//
// ~ 1 mimic / 1 eth / 1 day
//
//               target price      with 18 decimals     per 24 hours ------------------------------------------------------------]
// guildRate18 = BigNumber("1e18").multipliedBy("1e18").multipliedBy("60").multipliedBy("60").multipliedBy("24").dividedBy("1e18");
//             = 86400000000000000000000

contract MimicologistsGuild is CoreGuild {
    constructor()
        CoreGuild(1438269988, 86400000000000000000000)
        {}

    function innerLore() internal pure override returns (string memory) {
         return ""
        "MIMICS"
        "\n\n"

        "The Mimic [Mimicus Etheriensis] is a mischevious but honorable "
        "digital creature that lives deep within the ethereum blockchain."
        "\n\n"

        "Mimicologists have noted the contrast between the mimic's curious and exploratory "
        "juvenile state, and the stoic and disciplined adult state. The transition between these "
        "states being moderated by a strict ritualistic practice."
        "\n\n"

        "JUVENILE MIMICS"
        "\n\n"

        "Juvenile mimics have been observed on various Expedition()s. The young mimics "
        "are generally bright in color with flickering facial elements. When discovered, "
        "juvenile mimics are known to develop an immediate affinity to the explorer who "
        "finds them, henceforth allowing the explorer to act as the mimic's caretaker. Interestingly, "
        "all Expedition()s to date have each found one and only one juvenile mimic."
        "\n\n"

        "Juvenile mimics have been observed to playfully poke other NFTs that they are presented "
        "with from throughout the ethereum ecosystem. This immediately results in the mimic "
        "transforming to have the appearance of the poked NFT. The change in the creature's appearance "
        "can be the source of some confusion and amusement and is what gives the mimic its name."
        "\n\n"

        "A juvenile mimic that has previously poked another NFT may at a later time Relax(). This "
        "results in the mimic returning to its normal juvenile appearance."
        "\n\n"

        "A transformed mimic may also sometimes poke another NFT without first Relax()ing. "
        "This results in the mimic losing the appearance of the previous NFT and changing to have "
        "the appearance of the new NFT."
        "\n\n"

        "POKE 721"
        "\n\n"

        "In order to successfully Poke721() an ERC721 NFT, the poking mimic must be informed as to "
        "the contract address and tokenId of the NFT in question."
        "\n\n"

        "POKE 1155"
        "\n\n"

        "In order to successfully Poke1155() an ERC1155 NFT, the poking mimic must be informed as to "
        "the contract address, tokenId and the address of the owner of the NFT in question."
        "\n\n"

        "MIMIC RITES OF ADULTHOOD"
        "\n\n"

        "The second and final stage of a mimic's lifecycle is the adult stage. Transition to this "
        "stage requires the undertaking of a sacred rite that conforms to the rules and "
        "expectations of mimic society. A mimic can only undertake a rite if it has poked and not "
        "relaxed from that poke. The nature of the rite that can be performed is dependent on the nature "
        "of the poked NFT."
        "\n\n"

        "During a rite, the mimic sheds its superficial ephemeral essence, which is then reified into "
        "a mimic shield. Mimic shields are distinct objects that have a notable similarity "
        "of character to the juvenile form of mimic from whom then were crafted. Before the rite "
        "completes, the shield is presented to the owner of the poked NFT."
        "\n\n"

        "In the undertaking of the rite, the mimic's form is forever frozen to that of the poked NFT. "
        "Mimic society dictates that no other mimic may ever again poke that same NFT, and any other "
        "juvenile mimics who have already also poked the NFT will revert to thier natural appearence."
        "\n\n"

        "RITE OF 721"
        "\n\n"

        "Undertaking the RiteOf721() requires a mimic to have poked an NFT conforming to the standards "
        "commonly known as ERC721. The mimic is permanently bound to the form of that NFT and the "
        "oiner of the poked NFT is presented with the mimic's shield."
        "\n\n"

        "RITE OF 1155"
        "\n\n"

        "Undertaking the RiteOf1155() requires a mimic to have poked an NFT conforming to the standards "
        "commonly known as ERC1155. In addition, the rite must be given knowledge of the owner of "
        "the poked NFT. The mimic is permanently bound to the form of the poked NFT and the NFT owner is "
        "presented with the mimic's shield."
        "\n\n"

        "DETERMINING INFORMATION ABOUT NFTS"
        "\n\n"

        "While contract, tokenId, and ownership can sometimes be hard to determine, many mimic caretakers have had luck "
        "asking the sailors around the ports for information, it seems there is much to be learned from "
        "those who travel the open sea."
        "\n\n"

        "The Mimicologists Guild also employs a number of tokenologists who's services are made available to the "
        "public for no cost."
        "\n\n"

        "MIMIC SHIELDS"
        "\n\n"

        "Mimic Shields are rare artifacts forged during a mimic rite, and bestowed upon the owners of "
        "entangled NFTs at the rite's completion. Aside from thier A E S T H E T I C and symbolic value, shields "
        "have an additional power of aura that may be Activate()d or Deactivate()d at the discretion of the shield's "
        "holder."
        "\n\n"

        "If a shield holder would like to ward off all poking upon the NFTs in thier collection "
        "they can Activate() the aura on one or more of their shields. Mimics will refuse to poke "
        "any NFT who's owner also holds a mimic shield with an activated aura."
        "\n\n"

        "Equally, if a shield owner would like to allow mimics to poke at and entagle their NFTs in rites, either for "
        "prestige or for the prospect of acquiring more shields, the may choose to Deactivate() all of the shields in "
        "their collection. Deactivated shields will be ignored by mimics and provide no aura. Mimics will however "
        "never poke a shield itself as this is forbidden by mimic society."
        "\n\n"

        "All shields are initially deactivated when forged, and may be Activate()d and Deactivate()d without limit."
        "\n\n"

        "THE MIMICOLOGISTS GUILD"
        "\n\n"

        "The Mimicologists Guild organizes various Expedition()s to foreign lands known to be inhabited by "
        "mimics. While ships and sailors are freely supplied by the guild, there is a constraint on the available "
        "sauerkraut for stocking such voyages and hence a natural limit to the rate at which Expedition()s "
        "can be undertaken at a reasonable price. When an Expedition() is undertaken, the guild will expect "
        "an associated payment to cover the cost of sauerkraut which will vary over time."
        "\n\n"

        "For the benefit of prospective voyagers, the guild provides functionality to "
        "GetExpeditionCostInWei() at the current date and time based on the sauerkraut markets. "
        "If few Expedition()s are undertaken the cost of sauerkraut decreases and Expedition()s become "
        "cheaper to stock, and conversely if many Expedition()s are undertaken faster than the sauerkraut "
        "markets can supply them then the cost of funding Expedition()s will tend to go up."
        "\n\n"

        "NOTE: At the time of writing there is a large surplus of sauerkraut on the market. The cost of "
        "funding Expedition()s should be low until this excess stock has been consumed."
        "\n\n"

        "";
    }
}

