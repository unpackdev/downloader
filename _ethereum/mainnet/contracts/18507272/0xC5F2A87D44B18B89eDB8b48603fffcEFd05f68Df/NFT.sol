import "./ERC721.sol";
import "./Base64.sol";

contract NFT is ERC721 {
    constructor(address to) ERC721("NFT", "NFT") {
        _safeMint(to, 0);
    }

function tokenURI(uint256 tokenId) public view override returns (string memory) {
    string memory base = "data:application/json;base64,";
    string memory json = 
    "{\"name\":\"\u4e00\u5207\",\"description\":\"\u4e00\u5207\u662f\u4e00\u5207\",\"image\":\"data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIj8+PHN2ZyB3aWR0aD0iNTEyIiBoZWlnaHQ9IjUxMiIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48Zz48ZyBpZD0ic3ZnXzEiPjxnIGlkPSJzdmdfMiI+PHBhdGggaWQ9InN2Z18zIiBkPSJtMTYwLjgwNCwyMDUuOTAyYy0yNy42MjUsMCAtNTAuMDk4LDIyLjQ3MyAtNTAuMDk4LDUwLjA5OHMyMi40NzMsNTAuMDk4IDUwLjA5OCw1MC4wOThjMjguNzg4LDAgNTIuOTc5LC0yMy4wNzYgNzcuNjgsLTUwLjA5OGMtMjQuNzAyLC0yNy4wMjIgLTQ4Ljg5MSwtNTAuMDk4IC03Ny42OCwtNTAuMDk4eiIgLz48L2c+PC9nPjxnIGlkPSJzdmdfNCI+PGcgaWQ9InN2Z181Ij48cGF0aCBpZD0ic3ZnXzYiIGQ9Im0zNTEuMTk2LDIwNS45MDJjLTI4Ljc4OCwwIC01Mi45NzksMjMuMDc2IC03Ny42OCw1MC4wOThjMjQuNywyNy4wMjIgNDguODkxLDUwLjA5OCA3Ny42OCw1MC4wOThjMjcuNjI1LDAgNTAuMDk4LC0yMi40NzMgNTAuMDk4LC01MC4wOThzLTIyLjQ3MywtNTAuMDk4IC01MC4wOTgsLTUwLjA5OHoiIC8+PC9nPjwvZz48ZyBpZD0ic3ZnXzciPjxnIGlkPSJzdmdfOCI+PHBhdGggaWQ9InN2Z185IiBkPSJtMjU2LDBjLTE0MS4xNTYsMCAtMjU2LDExNC44MzkgLTI1NiwyNTZzMTE0Ljg0NCwyNTYgMjU2LDI1NnMyNTYsLTExNC44MzkgMjU2LC0yNTZzLTExNC44NDQsLTI1NiAtMjU2LC0yNTZ6bTEwMC4xOTYsMzM5LjQ5NmMtNDEuNDY1LDAgLTcxLjg5NiwtMjcuOTE5IC0xMDAuMTk2LC01OC42MzJjLTI4LjMsMzAuNzEzIC01OC43Myw1OC42MzIgLTEwMC4xOTYsNTguNjMyYy00Ni4wNDIsMCAtODMuNDk2LC0zNy40NTQgLTgzLjQ5NiwtODMuNDk2YzAsLTQ2LjA0MiAzNy40NTQsLTgzLjQ5NiA4My40OTYsLTgzLjQ5NmM0MS40NjUsMCA3MS44OTYsMjcuOTE5IDEwMC4xOTYsNTguNjMyYzI4LjMsLTMwLjcxMyA1OC43MywtNTguNjMyIDEwMC4xOTYsLTU4LjYzMmM0Ni4wNDIsMCA4My40OTYsMzcuNDU0IDgzLjQ5Niw4My40OTZjMCw0Ni4wNDIgLTM3LjQ1NCw4My40OTYgLTgzLjQ5Niw4My40OTZ6IiAvPjwvZz48L2c+PC9nPjwvc3ZnPg==\",\"attributes\":[{\"trait_type\":\"\u59d3\u540d\",\"value\":\"\u6797\u4f5b\u94a7\"},{\"trait_type\":\"\u5c5e\u6027\",\"value\":\"\u4e00\u5207\"},{\"trait_type\":\"\u5c5e\u6027\",\"value\":\"\u5b58\u5728\"},{\"trait_type\":\"\u5c5e\u6027\",\"value\":\"\u65e0\u7a77\"}]}";
    string memory encodedJson = Base64.encode(bytes(json));
    return string(abi.encodePacked(base, encodedJson));
}
}