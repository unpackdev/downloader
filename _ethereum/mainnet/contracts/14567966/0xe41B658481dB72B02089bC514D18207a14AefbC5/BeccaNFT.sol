// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721.sol";
import "./base64.sol";

contract BeccaNFT is ERC721 {
    uint256 public constant SECONDS_IN_YEAR = 31540000;
    uint256 private immutable i_startingTimeStamp;
    string private constant BASE_URI = "data:application/json;base64,";

    string[21] private s_images = [
        "ipfs://Qmb5MuG5pCrTtWix9xnNHfVRjXToVwW9gAP2tV814Mp1Y3", // image 3 is index 0
        "ipfs://QmScf3nifspmAckZDqS1jvzjsNFTZ1UzWZA4jHqMmnaxfG",
        "ipfs://QmPfxzYxWPRb74iEcTGjraU2VmAcmc4uCHRiFYG8BH2cdN",
        "ipfs://QmZn1bMvjq7BuSnLnqnGtswy9Tkb87R3CiL8sXZAp49AGH",
        "ipfs://QmZFuhZLGsehNkue35SmLzGbDDV6KcePbjoLWEVW7LCHQy",
        "ipfs://QmQPooA27wMXFYBi1cK5RycohyhEC97hA7j9xLDmkto3mR",
        "ipfs://QmZVQwEMg3DpVFqkuJezFxpkX6DqbDuCK8jGXHaCq2M2Ri",
        "ipfs://QmddpZo2X2PQgYThsK3xZ5s5C2AcTTpfGfAsFeRZSh4DNm",
        "ipfs://Qma4oViT1sE6Upkz8wvaEXA4grYCXsgn8Q2nZWqrFhy3s6",
        "ipfs://QmQkzCSrFFAuMAFeE4p3WdNvD4P7Ys7wXFXSiYBuuj1zjQ",
        "ipfs://Qma2KS4eTPUzWtc5Ys1UF9BoY4SYSob1DJHtq3Ht8VLCbS",
        "ipfs://QmegAMAEhpj48u5FuSXqFZ7vNtopidPNh3qQi5J1bZ631u",
        "ipfs://QmaMV9syU5zQyjaKCfA3GVz8c86a4zCkY6N2h9BuVhiNot",
        "ipfs://QmamPXyKW4XsyxAZLhoxpceF3nFUgvBPKTo49ydCiYbDo7",
        "ipfs://QmWx5UQj7LZyGRnVK4hGrpPRdXduqpyGKhebAn7fSZqe4A",
        "ipfs://QmaYRLzVx6AvWiCWwB914sQFXXTicSHfAWePFPwp2GfFL5",
        "ipfs://QmUBGUaNDe2mHoMoCaozDVJ283mWR4vC6Ui9SmzaaNnxcP",
        "ipfs://QmegpSVz6QwcFNgE9qeQ8ov32DAxgcvcauttekSSALEtXC",
        "ipfs://QmdZAuS7FbsgsQsh3DvR5BzjviQbkUdzisR3bTt8DtL9BA",
        "ipfs://QmWXkpFAb6LyYbF7WrU14Cz8MVqAhBdfajqoQSdvLLwqLb",
        "ipfs://Qmb5MuG5pCrTtWix9xnNHfVRjXToVwW9gAP2tV814Mp1Y3" // and also our last one image 3 is index 20
    ];

    constructor() ERC721("Bex Toaster NFT", "TBEX") {
        _mint(msg.sender, 0);
        i_startingTimeStamp = block.timestamp;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "BeccaNFT: URI query for nonexistent token");

        uint256 imageURIIndex = getImageURIIndex();
        string memory imageURI = s_images[imageURIIndex];

        return
            string(
                abi.encodePacked(
                    BASE_URI,
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name(), // You can add whatever name here
                                '", "description":"Bex & Patrick - Just a frog and a penguin chilling with a toaster in the cloud...Also there is a gator.", ',
                                '"attributes": [{"trait_type": "cuteness", "value": 100}], "image":"',
                                imageURI,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function getImageURIIndex() public view returns (uint256) {
        uint256 index = ((block.timestamp - i_startingTimeStamp) / SECONDS_IN_YEAR);
        if (index > 20) {
            index = 20;
        }
        return index;
    }

    function getStartingTimeStamp() public view returns (uint256) {
        return i_startingTimeStamp;
    }

    function getImageURI(uint256 index) public view returns (string memory) {
        return s_images[index];
    }
}
