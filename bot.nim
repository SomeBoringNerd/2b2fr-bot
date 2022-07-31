import asyncdispatch, json, options, dimscord, strutils, harpoon, strformat, dimscmd, os, times
from uri import parseUri


discard os.execShellCmd("clear")
let discord = newDiscordClient(readFile("token.key").split("\n")[0])
var cmd = discord.newHandler()

const
    colors = 0x670067
    api = "https://api.2b2fr.xyz"

proc onReady(s: Shard, r: Ready) {.event(discord).} =
    try:
        await cmd.registerCommands()
        echo fmt"Login on {$r.user}"
    except Exception as e:
        echo e.msg

proc interactionCreate(s: Shard, i: Interaction) {.event(discord).} =
    discard await cmd.handleInteraction(s, i)

cmd.addSlash("help") do ():
    ## Help command
    let res = InteractionResponse(
        kind: irtChannelMessageWithSource,
        data: some InteractionApplicationCommandCallbackData(
            embeds: @[Embed(
                title: some "2b2fr.xyz help menu",
                fields: some @[EmbedField(
                    name: "**/status**",
                    value: "```Display player count```",
                    inline: some true
                ),
                EmbedField(
                    name: "**/plugins**",
                    value: "```Display all plugins used on the server```",
                    inline: some true
                ),
                EmbedField(
                    name: "**/joindate <player>**",
                    value: "```Display the join date of a given player```"
                ),
                EmbedField(
                    name: "**/playtime <player>**",
                    value: "```Display the playtime of a given player```"
                ),
                EmbedField(
                    name: "**/kdr <player>**",
                    value: "```Displays the KDR(Kill Death Ratio) of a given player```"
                ),
                EmbedField(
                    name: "**/namemc <player>**",
                    value: "```Displays information on a minecraft profile```"
                ),
                EmbedField(
                    name: "**/quote**",
                    value: "```Generates a random quote```"
                )],
                color: some colors,
                footer: some EmbedFooter(
                    text: "Made by TaxMachine",
                    icon_url: some "https://cdn.discordapp.com/avatars/795785229699645491/d5e35455f6a23a2e6fef88e3416d7a9b.webp"
                )
            )]
        )
    )
    await discord.api.createInteractionResponse(i.id, i.token, res)

cmd.addSlash("status") do ():
    ## Displays player count
    var players = getContent(parseUri(fmt"{api}/status"))
    let res = InteractionResponse(
        kind: irtChannelMessageWithSource,
        data: some InteractionApplicationCommandCallbackData(
            embeds: @[Embed(
                title: some "**Player Count**",
                description: some fmt"```{players} Players```",
                color: some colors,
                footer: some EmbedFooter(
                    text: "Made by TaxMachine",
                    icon_url: some "https://cdn.discordapp.com/avatars/795785229699645491/d5e35455f6a23a2e6fef88e3416d7a9b.webp"
                )
            )]
        )
    )
    await discord.api.createInteractionResponse(i.id, i.token, res)

cmd.addSlash("namemc") do (player: string):
    ## Search a minecraft username on namemc
    let
        data = getJson(parseUri(fmt"https://api.ashcon.app/mojang/v2/user/{player}"))
    var res: InteractionResponse
    if (data{"code"}.getInt() == 404):
        res = InteractionResponse(kind: irtChannelMessageWithSource, data: some InteractionApplicationCommandCallbackData(content: "user not found"))
    else:
        var
            uuid = data["uuid"].getStr
            username = data["username"].getStr
            date = data{"created_at"}.getStr
            usernamehistory = data["username_history"]
            hist = ""
        if (usernamehistory.len > 0):
            for names in usernamehistory:
                if (names{"changed_at"}.isNil):
                    hist.add(names["username"].getStr & " : Original\n")
                else:
                    var
                        cdate = names{"changed_at"}.getStr.split("T")
                        pdate = cdate[1].split(".")[0] & " " & cdate[0]
                    hist.add(names["username"].getStr & fmt" : {pdate}{'\n'}")
        else:
            hist.add("No Name History")
        res = InteractionResponse(
            kind: irtChannelMessageWithSource,
            data: some InteractionApplicationCommandCallbackData(
                embeds: @[Embed(
                    title: some "Namemc Lookup",
                    fields: some @[EmbedField(
                        name: "**username**",
                        value: fmt"```{'\n'}{username}{'\n'}```",
                        inline: some true
                        ),
                        EmbedField(
                        name: "**UUID**",
                        value: fmt"```{'\n'}{uuid}{'\n'}```",
                        inline: some true
                        ),
                        EmbedField(
                        name: "**Creation Date(Might not be given)**",
                        value: fmt"```{'\n'}{date}{'\n'}```",
                        inline: some true
                        ),
                        EmbedField(
                        name: "**Name History**",
                        value: fmt"```fix{'\n'}{hist}{'\n'}```",
                        inline: some false
                        )
                    ],
                    thumbnail: some EmbedThumbnail(
                        url: some fmt"https://crafatar.com/avatars/{uuid}"
                    ),
                    image: some EmbedImage(
                        url: some fmt"https://crafatar.com/renders/body/{uuid}"
                    ),
                    color: some colors,
                    footer: some EmbedFooter(
                        text: "Made by TaxMachine",
                        icon_url: some "https://cdn.discordapp.com/avatars/795785229699645491/d5e35455f6a23a2e6fef88e3416d7a9b.webp"
                    )
                )]
            )
        )
    await discord.api.createInteractionResponse(i.id, i.token, res)

cmd.addSlash("plugins") do ():
    ## Displays in-game plugin list
    let pluginlist = getJson(parseUri"https://api.2b2fr.xyz/plugin")
    var plugins = ""
    for plug in pluginlist:
        plugins.add(fmt"{plug}{'\n'}")
    let res = InteractionResponse(
        kind: irtChannelMessageWithSource,
        data: some InteractionApplicationCommandCallbackData(
            embeds: @[Embed(
                title: some "**Plugin List**",
                description: some fmt"```{'\n'}{plugins}{'\n'}```",
                color: some colors,
                footer: some EmbedFooter(
                    text: "Made by TaxMachine",
                    icon_url: some "https://cdn.discordapp.com/avatars/795785229699645491/d5e35455f6a23a2e6fef88e3416d7a9b.webp"
                )
            )]
        )
    )
    await discord.api.createInteractionResponse(i.id, i.token, res)

cmd.addSlash("kdr") do (player: string):
    ## Displays the KDR of a given player
    let
        kd = getJson(parseUri(fmt"https://api.2b2fr.xyz/kd?player={player}"))
        kill = kd["kill"].getStr
        death = kd["death"].getStr
    let res = InteractionResponse(
            kind: irtChannelMessageWithSource,
            data: some InteractionApplicationCommandCallbackData(
                embeds: @[Embed(
                    title: some fmt"`{player}`'s **kdr**",
                    fields: some @[EmbedField(
                        name: "**Kill**",
                        value: fmt"```{kill} kills```"
                    ),
                    EmbedField(
                        name: "**Death**",
                        value: fmt"```{death} deaths```"
                    )],
                    footer: some EmbedFooter(
                        text: "Made by TaxMachine",
                        icon_url: some "https://cdn.discordapp.com/avatars/795785229699645491/d5e35455f6a23a2e6fef88e3416d7a9b.webp"
                    ),
                    color: some colors
                )]
            )
        )
    await discord.api.createInteractionResponse(i.id, i.token, res)

cmd.addSlash("playtime") do (player: string):
    ## Displays the playtime of a given player
    let
        playtime = getJson(parseUri(fmt"https://api.2b2fr.xyz/pt?player={player}"))
        time = $playtime["playTime"].getInt
    let res = InteractionResponse(
            kind: irtChannelMessageWithSource,
            data: some InteractionApplicationCommandCallbackData(
                embeds: @[Embed(
                    title: some fmt"`{player}`'s **playtime**",
                    description: some fmt"```{time} hours```",
                    footer: some EmbedFooter(
                        text: "Made by TaxMachine",
                        icon_url: some "https://cdn.discordapp.com/avatars/795785229699645491/d5e35455f6a23a2e6fef88e3416d7a9b.webp"
                    ),
                    color: some colors
                )]
            )
        )
    await discord.api.createInteractionResponse(i.id, i.token, res)

cmd.addSlash("joindate") do (player: string):
    ## Displays the join date of a given player
    let
        joindate = getJson(parseUri(fmt"https://api.2b2fr.xyz/jd?player={player}"))
        time = times.fromUnix(joindate["joinDate"].getInt).utc
    let res = InteractionResponse(
            kind: irtChannelMessageWithSource,
            data: some InteractionApplicationCommandCallbackData(
                embeds: @[Embed(
                    title: some fmt"`{player}`'s **join date**",
                    description: some fmt"`{time}`",
                    footer: some EmbedFooter(
                        text: "Made by TaxMachine",
                        icon_url: some "https://cdn.discordapp.com/avatars/795785229699645491/d5e35455f6a23a2e6fef88e3416d7a9b.webp"
                    ),
                    color: some colors
                )]
            )
        )
    await discord.api.createInteractionResponse(i.id, i.token, res)

cmd.addSlash("quote") do ():
    ## Generates a random quote
    let
        quote = getContent(parseUri"https://inspirobot.me/api?generate=true")
        res = InteractionResponse(
            kind: irtChannelMessageWithSource,
            data: some InteractionApplicationCommandCallbackData(
                embeds: @[Embed(
                    title: some "Fun quote",
                    image: some EmbedImage(
                        url: some quote
                    ),
                    color: some colors
                )]
            )
        )
    await discord.api.createInteractionResponse(i.id, i.token, res)

waitFor discord.startSession()