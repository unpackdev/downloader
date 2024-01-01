// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20Interface {
    function mint(address usr, uint wad) external;
    function burnFrom(address src, uint wad) external;
    function balanceOf(address usr) external returns (uint);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
}

contract TokenSwap {
  
    // Exchange ratios for each token
    uint256 public ratioSWSH;
    uint256 public ratioRTC;
    uint256 public ratioLIQLO;
    uint256 public ratioSPECTRE;

    // Destination address for input tokens
    address public inputTokenDestination;
    
    ERC20Interface public SWSH;
    ERC20Interface public RTC;
    ERC20Interface public LIQLO;
    ERC20Interface public SPECTRE;
    ERC20Interface public PSHP;
    
    mapping (address => uint) public blocks;
    mapping (address => bool) public owners;

    // Constructor to initialize contract with token addresses and exchange ratios
    constructor() {
        owners[msg.sender] = true;
        inputTokenDestination = msg.sender;
        
        ratioSWSH = 6171399053000000000;
        ratioRTC = 8916187149000000000;
        ratioLIQLO = 2670096288000000000;
        ratioSPECTRE = 33913829810000000000;
        
        SWSH = ERC20Interface(0x3ac2AB91dDF57e2385089202Ca221C360CED0062);
        RTC = ERC20Interface(0x7f9A00E03c2E53A3aF6031C17A150DBeDaAab3dC);
        LIQLO = ERC20Interface(0x59AD6061A0be82155E7aCcE9F0C37Bf59F9c1e3C);
        SPECTRE = ERC20Interface(0x441d91F7AAEe51C7AE8cAB84333D6383A8a8C175);
        PSHP = ERC20Interface(0x88D59Ba796fDf639dEd3b5E720988D59fDb71Eb8);
    }
    
    function control() internal returns (bool) {
        require((msg.sender == tx.origin), "Access denied");
        require((blocks[msg.sender] < block.number), "Block used");

        blocks[msg.sender] = block.number;
        return true;
    }

    // Swap function for exchanging input tokens for output token X
    function swapTokens(uint256 amountSWSH, uint256 amountRTC, uint256 amountLIQLO, uint256 amountSPECTRE) public {
        require(control());
        
        // Calculating the total output tokens with higher precision
        uint256 totalOutputX = (amountSWSH * 10**18 / ratioSWSH) +
                               (amountRTC * 10**18 / ratioRTC) +
                               (amountLIQLO * 10**18 / ratioLIQLO) +
                               (amountSPECTRE * 10**18 / ratioSPECTRE);

        require(totalOutputX > 0 && PSHP.balanceOf(address(this)) >= totalOutputX, "Insufficient token PSHP amount");

        // Transfer input tokens from the user to the destination address
        if(amountSWSH > 0) {
            require(SWSH.transferFrom(msg.sender, inputTokenDestination, amountSWSH), "Transfer of token SWSH failed");
        }
        if(amountRTC > 0) {
            require(RTC.transferFrom(msg.sender, inputTokenDestination, amountRTC), "Transfer of token RTC failed");
        }
        if(amountLIQLO > 0) {
            require(LIQLO.transferFrom(msg.sender, inputTokenDestination, amountLIQLO), "Transfer of token LIQLO failed");
        }
        if(amountSPECTRE > 0) {
            require(SPECTRE.transferFrom(msg.sender, inputTokenDestination, amountSPECTRE), "Transfer of token SPECTRE failed");
        }

        // Transfer output tokens to the user
        require(PSHP.transfer(msg.sender, totalOutputX), "Transfer of token PSHP failed");
    }
    
    function depositTokenX(uint256 amount) public {
        require(owners[msg.sender] == true);
        require(PSHP.transferFrom(msg.sender, address(this), amount), "Deposit of token PSHP failed");
    }
    
    function withdrawTokenX(uint256 amount) public {
        require(owners[msg.sender] == true);
        require(PSHP.transfer(msg.sender, amount), "Withdrawal of token PSHP failed");
    }
}