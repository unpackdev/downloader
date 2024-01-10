//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::;'............,::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::;,''''.............''''';:::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::;;'.   .lxxxxxxxxxxxx;    .;;:::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::'..',,,,:::::::::::::;,,,,...,::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::;....',;;;;;;;;;;;;;;;;;;;;;;,'...'::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::,.';:coodddddddddddddddddddddddddol:,.';:::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::. .d0000OkkkOKXXXXKXXXXXKK0kkkk0KXXK: .,:::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::;;..'d0KKOo::,cOXXXXXXXXXXXKxc:;;dKXXKc..,;;:::::::::::::::::::::::::::::
::::::::::::::::::::::::::,..;kOKKKKKOkc.;kXXXXXKXXXXXX0Od,.oKXXKOxl. ':::::::::::::::::::::::::::::
::::::::::::::::::::::::'..:lkKXXXXXKKKOxk0XXXXXXXXXXXXKK0xxOXXXKKKd. .:::::::::::::::::::::::::::::
::::::::::::::::::::::::. .d00KXXXXXKXXXXXXXXXXXXXXXXXXXXXXXXXXXXKXx. .:::::::::::::::::::::::::::::
::::::::::::::::::::::::'..:lxKKXXXXXXXXXXXXXXXXXXXXXXXKXXXXXXXXXKXx. .:::::::::::::::::::::::::::::
::::::::::::::::::::::::::,. ;O0KXXXXXXXXXXXXXXXX0OOOOOOOOOOOOOOO0Xx. .:::::::::::::::::::::::::::::
::::::::::::::::::::::::::,. ;O0KXXXXXXXXXXXKKKKKl...............lKx. .:::::::::::::::::::::::::::::
::::::::::::::::::::::::::;,''';x0KXXXXXXXXKOxo;,;::c::ccc::cc:;,,,,'';:::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::. .d00XXXXXXXXK0kxlc;,,,,,,,,,,,,,'.. .,:::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::'..:oxKKXXXXXXXXXXXKo,,''''''',''.   ..;:::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::,. ;dk0KKXXXXXXXXXXKKKKKKKKKKOxl. .;:::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::;....'x00KXXXXXXXXXKXXXXXXK0Oc....'::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::;'''',,,''o0KKXXXXXXXXXXXXKKk;'',,'''.';:::::::::::::::::::::::::::::::
::::::::::::::::::::::::::;,'''';::c:,',;lkKKKKKKKKK0KKd:;'';cc::,''',;:::::::::::::::::::::::::::::
::::::::::::::::::::::::::;'.'',;:ccccc,.'okxxkxkxxxkkx:..:cccc::;'''.,:::::::::::::::::::::::::::::
::::::::::::::::::::::;;;;;;;,..',;:cccccccccccccccccccccccccc:,,'..,;;;;;;:::::::::::::::::::::::::
:::::::::::::::::::::;'......','..',;:cccccccccccccccccccccc:;,..','.......,::::::::::::::::::::::::
::::::::::::::::;'......,;;;;::::;,...',;:cc;''''''',:c:;;''...,;:::;;;;,''....',:::::::::::::::::::
::::::::::::::::;.....,;:ccccccccc:,,,,'''',''',,'''',,'.',,,,;cccccccccc:;,....,:::::::::::::::::::
::::::::::::::;;,..',;ccccccccccccccccc;''..';:cc:::,...',:cccccccccccccccc:;,..',;:::::::::::::::::
::::::::::::::,....,ccccccc::cccccccccccc:'.,ccccccc:'.;ccccc:cccccc::ccccccc:.....;::::::::::::::::
::::::::::::::,..'';cccccc:'.',,:cccccccccc:cccccccccc:ccccc;,;:ccc:'.;cccccc:,'...;::::::::::::::::
:::::::::::;'....;:ccccccc:...',:ccccccccccccccccccccccccccc;',:ccc:..,ccccccc::'....,::::::::::::::
:::::::::::;....':cccccccc:...',:ccccccccccccccccccccccccccc:;;;;:c:..,ccccccccc,....,::::::::::::::
:::::::::::;..',;:cccccccc:..',;cccccccccccccccccccccccccccccc:,',:;..,ccccccccc:;,..,::::::::::::::
:::::::::::;..,ccccccccccc:..,cccccccccccccccccccccccccccccccc:;,,''..,:cccccccccc:..,::::::::::::::
:::::::::::;..,ccccccccc:,'..,cccccccccccccccccccccccccccccccccc:;''...,;:cccccccc:..,::::::::::::::
:::::::::::;..,ccccccccc;''..,ccccccccccccccccccccccccccccccccccc;''...',:cccccccc:..,::::::::::::::
:::::::::::;..,ccccccccc;....;ccccccccccccccccccccccccccccccccccc;''....':cccccccc:..,::::::::::::::
:::::::::::;..,ccccccccc,..'';ccccccccccccccccccccccccccccccccccc:,,,'...:cccccccc:..,::::::::::::::
:::::::::::;..,cccccccc:,..'';ccccccccccccccccccccccccccccccccccccc:;,...;cccccccc:..,::::::::::::::
:::::::::::;..,cccccc:;,...',;ccccccccccccccccccccccccccccccccccccccc:,...';cccccc:..,::::::::::::::
:::::::::::;..,cccccc:,'...;:cccccccccccccccccccccccccccccccccccccc:,'.....,;:cccc:..,::::::::::::::
:::::::::::;..'::cccc:'...',;:ccccccccccccccccccccccccccccccccc:;;;,''....',::cccc:..,::::::::::::::
:::::::::::;...,;:ccc:...'''';cccccccccccccccccccccccccccccccc:,''''''...'';cccccc:..,::::::::::::::
crypto monks.                                                                                                       
*/


import "./Ownable.sol";
import "./IERC721.sol";

abstract contract ICryptoMonks is Ownable, IERC721 {
    function mint(address _owner, uint256 _tokenId) external virtual;

    function exists(uint256 _tokenId) external view virtual returns (bool);

    function getMaxSupply() external virtual returns (uint256);

    function tokensOfOwner(address _owner) external view virtual returns (uint256[] memory);
}