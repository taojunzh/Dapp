pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Curtoken is ERC20 {
    constructor() ERC20("Curtoken", "CES") {
        _mint(msg.sender, 10000 * 10 ** decimals());
    }
}
