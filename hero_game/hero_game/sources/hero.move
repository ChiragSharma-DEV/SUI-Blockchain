/// Hero Quest: dynamic Hero NFT + admin-issued reward tickets + soulbound badge.
module hero_game::hero;

use std::string::String;
use sui::display;
use sui::event;
use sui::package;

// ---------- Objects (Sui me har cheez ek "object" hai) ----------

/// One-Time-Witness: sirf Display setup ke liye chahiye. Ignore kar sakte ho.
public struct HERO has drop {}

/// Player ka Hero NFT. `key` = on-chain object, `store` = wallet/marketplace me move ho sakta hai.
public struct Hero has key, store {
    id: UID,
    name: String,
    level: u64,
    xp: u64,
}

/// Sirf game server (admin) ke paas hota hai. Iske bina XP ticket nahi ban sakta (anti-cheat).
public struct AdminCap has key, store {
    id: UID,
}

/// Game jeetne par server player ko ye ticket bhejta hai. `store` nahi hai => transfer nahi ho sakta.
public struct RewardTicket has key {
    id: UID,
    xp: u64,
}

/// Achievement badge. `store` nahi hai => soulbound (sell/transfer nahi hoga).
public struct Badge has key {
    id: UID,
    hero_id: ID,
    title: String,
}

// ---------- Events (frontend/judges explorer me dekh sakte hain) ----------

public struct HeroLeveledUp has copy, drop {
    hero_id: ID,
    new_level: u64,
}

// ---------- Constants ----------

const BADGE_LEVEL: u64 = 3;

// ---------- Setup (publish ke time ek baar chalta hai) ----------

fun init(otw: HERO, ctx: &mut TxContext) {
    let publisher = package::claim(otw, ctx);

    // Display: wallet me NFT ka naam + image dikhane ke liye. {name}, {level} object se bharte hain.
    let mut display = display::new_with_fields<Hero>(
        &publisher,
        vector[
            b"name".to_string(),
            b"description".to_string(),
            b"image_url".to_string(),
        ],
        vector[
            b"{name} (Lv {level})".to_string(),
            b"Hero Quest: ye NFT game jeetne par level up hota hai.".to_string(),
            b"https://api.dicebear.com/9.x/pixel-art/png?seed={name}".to_string(),
        ],
        ctx,
    );
    display.update_version();

    transfer::public_transfer(publisher, ctx.sender());
    transfer::public_transfer(display, ctx.sender());
    transfer::transfer(AdminCap { id: object::new(ctx) }, ctx.sender());
}

// ---------- Player actions ----------

/// Naya Hero mint karo (level 1, xp 0) aur apne wallet me lo.
#[allow(lint(self_transfer))]
public fun mint_hero(name: String, ctx: &mut TxContext) {
    let hero = Hero { id: object::new(ctx), name, level: 1, xp: 0 };
    transfer::public_transfer(hero, ctx.sender());
}

/// Ticket redeem karke Hero ko XP do. Level badhta hai, level 3 pe soulbound badge milta hai.
#[allow(lint(self_transfer))]
public fun redeem_ticket(hero: &mut Hero, ticket: RewardTicket, ctx: &mut TxContext) {
    let RewardTicket { id, xp } = ticket;
    id.delete();

    let old_level = hero.level;
    hero.xp = hero.xp + xp;
    while (hero.xp >= xp_needed(hero.level)) {
        hero.xp = hero.xp - xp_needed(hero.level);
        hero.level = hero.level + 1;
    };

    if (hero.level > old_level) {
        event::emit(HeroLeveledUp { hero_id: object::id(hero), new_level: hero.level });
    };

    if (old_level < BADGE_LEVEL && hero.level >= BADGE_LEVEL) {
        let badge = Badge {
            id: object::new(ctx),
            hero_id: object::id(hero),
            title: b"Rising Hero".to_string(),
        };
        transfer::transfer(badge, ctx.sender());
    };
}

// ---------- Admin (game server) action ----------

/// Game server player ko XP ticket bhejta hai. AdminCap ke bina call nahi ho sakta.
public fun issue_ticket(_: &AdminCap, xp: u64, player: address, ctx: &mut TxContext) {
    transfer::transfer(RewardTicket { id: object::new(ctx), xp }, player);
}

// ---------- Helpers / getters ----------

/// Agle level ke liye kitna XP chahiye: level 1 -> 100, level 2 -> 200, ...
fun xp_needed(level: u64): u64 { level * 100 }

public fun level(hero: &Hero): u64 { hero.level }

public fun xp(hero: &Hero): u64 { hero.xp }

#[test_only]
public fun init_for_testing(ctx: &mut TxContext) {
    init(HERO {}, ctx);
}
