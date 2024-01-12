pragma solidity ^0.8.6;

// █▀█ █▄░█ █░░ █▄█ █░█ █▀█ █▀ ░ ▀▄▀ █▄█ ▀█
// █▄█ █░▀█ █▄▄ ░█░ █▄█ █▀▀ ▄█ ▄ █░█ ░█░ █▄

// ╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋┏┓╋╋╋╋╋╋╋╋╋╋┏┓╋╋╋╋╋╋╋╋┏┓
// ╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋┃┃╋╋╋╋╋╋╋╋╋┏┛┗┓╋╋╋╋╋╋┏┛┗┓
// ┏━━┳━┳┳━━┳┳━┓┏━━┫┃╋┏━━┳━━┳━╋┓┏╋━┳━━┳━┻┓┏╋━━┓
// ┃┏┓┃┏╋┫┏┓┣┫┏┓┫┏┓┃┃╋┃┏━┫┏┓┃┏┓┫┃┃┏┫┏┓┃┏━┫┃┃━━┫
// ┃┗┛┃┃┃┃┗┛┃┃┃┃┃┏┓┃┗┓┃┗━┫┗┛┃┃┃┃┗┫┃┃┏┓┃┗━┫┗╋━━┃
// ┗━━┻┛┗┻━┓┣┻┛┗┻┛┗┻━┛┗━━┻━━┻┛┗┻━┻┛┗┛┗┻━━┻━┻━━┛
// ╋╋╋╋╋╋┏━┛┃
// ╋╋╋╋╋╋┗━━┛

// █▄░█ █▀▀ ▀█▀ █▀   █░░ █▀█ █▀▀ █▄▀ █▀▀ █▀▄   ▀█▀ █▀█   █▀▀ █▀█   █░█ █▀█
// █░▀█ █▀░ ░█░ ▄█   █▄▄ █▄█ █▄▄ █░█ ██▄ █▄▀   ░█░ █▄█   █▄█ █▄█   █▄█ █▀▀

// ONLYUPS.XYZ
// ORIGINAL CONTRACTS
// NFTS LOCKED TO GO UP

// BUILDING DEFI ON OPENSEA
// BUILDING DEFI ON OPENSEA
// BUILDING DEFI ON OPENSEA


interface IToken  {
    //721
    function ownerOf(uint256 tokenId) external view returns (address);
    function openMatch(uint256 _id, address _xored, address _conduit) external;
    function restoreMatch(uint256 _id, address _xoredToBuyer, address _xored) external;
    function closeMatch(uint256 _id, address _xored) external;
    //20
    function approve(address spender, uint value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    //weth
    function withdraw(uint wad) external;
}
