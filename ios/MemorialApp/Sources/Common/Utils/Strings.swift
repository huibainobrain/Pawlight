import Foundation

struct Strings {
    let l: AppLanguage

    init(_ l: AppLanguage) { self.l = l }

    private func t(_ zh: String, _ en: String) -> String { l == .zh ? zh : en }

    // MARK: - App

    var appName: String { t("留光", "Pawlight") }

    // MARK: - Tabs

    var tabHome: String   { t("首页", "Home") }
    var tabMemory: String { t("回忆", "Memories") }
    var tabMe: String     { t("我的", "Me") }

    // MARK: - Common

    var cancel: String          { t("取消", "Cancel") }
    var save: String            { t("保存", "Save") }
    var edit: String            { t("编辑", "Edit") }
    var delete: String          { t("删除", "Delete") }
    var close: String           { t("关闭", "Close") }
    var ok: String              { t("好的", "OK") }
    var laterBtn: String        { t("稍后再说", "Maybe later") }
    var continueEditing: String { t("继续编辑", "Keep editing") }
    var leaveWithoutSaving: String { t("不保存离开", "Leave without saving") }
    var leaveBtn: String        { t("先离开", "Leave") }
    var next: String            { t("下一步", "Next") }
    var creating: String        { t("创建中...", "Creating...") }
    var uploading: String       { t("上传中...", "Uploading...") }
    var reload: String          { t("重新加载", "Reload") }
    var saveFailed: String      { t("保存失败", "Save failed") }
    var saveFailedBody: String  { t("暂时没有保存成功，请稍后再试。", "Couldn't save — please try again.") }
    var startCreate: String     { t("开始创建", "Get started") }
    var createKeepsake: String  { t("为TA创建星球", "Create their little planet") }
    var learnMore: String       { t("先了解一下", "Learn more") }
    var explorePlan: String     { t("了解完整纪念空间", "Explore the full plan") }

    // MARK: - Pet types

    func petTypeName(_ type: Pet.PetType) -> String {
        switch type {
        case .cat:   return t("猫猫", "Cat")
        case .dog:   return t("狗狗", "Dog")
        case .other: return t("其他小动物", "Other")
        }
    }

    // MARK: - Onboarding Start

    var onboardingTitle: String   { t("为TA留下一颗星球", "Create a little planet for the pet you remember") }
    var onboardingBody: String    { t("先留下TA的名字和一张照片，\n故事和回忆可以之后慢慢补充。", "Start with a name and a photo.\nYou can add more memories later.") }
    var onboardingFeature1: String { t("留下名字和照片", "Name and photo") }
    var onboardingFeature2: String { t("慢慢补充回忆", "Add memories over time") }
    var onboardingFeature3: String { t("分享给记得TA的人", "Share with those who remember") }
    var onboardingStartBtn: String { t("开始创建", "Get started") }

    // MARK: - Login

    var loginTitle: String  { t("登录以保存TA的星球", "Sign in to save their keepsake") }
    var loginBody: String   { t("账号让你可以随时回来，也让权益和\n纪念内容长期绑定。", "An account lets you return anytime\nand keeps everything safe.") }
    var loginTerms: String  { t("继续即表示同意《用户协议》和《隐私政策》", "By continuing, you agree to our Terms and Privacy Policy") }
    var loginError: String  { t("无法获取登录凭证", "Couldn't get credentials") }
    var loginErrorGeneral: String { t("登录遇到问题，请再试一次", "Something went wrong — please try again") }

    // MARK: - Pet Info

    var petInfoStep: String     { t("1 / 3  基础信息", "1 / 3  Basic info") }
    var petInfoTitle: String    { t("TA叫什么名字？", "What's their name?") }
    var petInfoBody: String     { t("先给TA取个名字，以后在这里\n我们就一起记住TA。", "Give them a name — we'll remember them here together.") }
    var petInfoNameLabel: String { t("名字", "Name") }
    var petInfoNamePlaceholder: String { t("TA的名字", "Their name") }
    var petInfoTypeLabel: String { t("TA是", "They are") }
    var petInfoExitTitle: String { t("暂时离开？", "Leave for now?") }
    var petInfoExitBody: String  { t("现在离开的话，本次填写的内容不会保存。", "If you leave now, what you've filled in won't be saved.") }
    var petInfoContinue: String  { t("继续创建", "Keep going") }
    var petInfoCreateError: String { t("创建失败，请重试", "Couldn't create — please try again") }
    var petInfoCanChange: String { t("创建后你可以随时修改", "You can change this later") }

    // MARK: - Main Photo

    var mainPhotoStep: String   { t("2 / 3  主照片", "2 / 3  Main photo") }
    var mainPhotoTitle: String  { t("选一张最想看到TA的照片", "Choose a photo you'd love to see") }
    func mainPhotoBody(_ name: String) -> String {
        t("主照片会显示在首页、回忆页和分享页，\n是\(name)的视觉锚点。",
          "This photo shows on the main screen, memory page, and share page —\nthe heart of \(name)'s keepsake.")
    }
    var mainPhotoPickLabel: String { t("点击选择照片", "Tap to choose a photo") }
    var mainPhotoChange: String    { t("更换照片", "Change photo") }
    var mainPhotoUploadError: String  { t("上传失败，请重试", "Upload failed — please try again") }
    var mainPhotoProcessError: String { t("图片处理失败", "Couldn't process image") }
    var mainPhotoExitTitle: String { t("暂时离开？", "Leave for now?") }
    var mainPhotoExitBody: String  { t("TA的星球已创建，但主照片还没有上传。可以稍后在回忆页继续补充。", "Their little planet has been created, but the main photo hasn't been uploaded yet. You can add it later from Memories.") }
    var mainPhotoContinueUpload: String { t("继续上传", "Keep uploading") }

    // MARK: - Tier Select

    var tierStep: String   { t("3 / 3  选择纪念空间", "3 / 3  Choose a plan") }
    func tierTitle(_ name: String) -> String {
        t("为\(name)选择一个纪念空间", "Choose a plan for \(name)")
    }
    var tierBody: String { t("不同方案，陪伴的方式不同。\n为TA选择一个最合适的家吧。", "Different plans, different ways to remember.\nFind the one that fits best.") }
    var tierFreeTitle: String    { t("免费纪念空间", "Free Plan") }
    var tierFreeSubtitle: String { t("先为TA留下一颗星球", "Start with a gentle keepsake") }
    var tierFreeBtnTitle: String { t("免费创建", "Start for free") }
    var tierPaidTitle: String    { t("完整纪念空间", "Full Plan") }
    var tierPaidSubtitle: String { t("更多照片，更完整的陪伴", "More photos, a fuller memorial") }
    var tierPaidBadge: String    { t("推荐", "Recommended") }
    var tierPaidLaunchPrice: String         { t("首发价格", "Launch price") }
    var tierPaidOneTimeUnlock: String       { t("一次性解锁", "One-time unlock") }
    var tierPaidPriceLoading: String        { t("价格加载中...", "Loading price...") }
    var tierPaidPriceUnavailable: String    { t("价格暂不可用", "Price unavailable") }
    var tierPaidPurchaseUnavailable: String { t("暂时无法购买", "Purchase unavailable") }
    var tierFutureTitle: String  { t("未来纪念形态", "More to come") }
    var tierFutureSubtitle: String { t("更多纪念可能，即将开放", "More memorial features, coming soon") }
    var tierFutureBadge: String  { t("暂未开放", "Coming soon") }
    var tierSelectPrompt: String { t("请选择一个方案", "Choose a plan") }
    var tierPurchaseErrorTitle: String { t("购买未完成", "Purchase not completed") }
    func tierPaidBtnTitle(_ price: String) -> String {
        t("开启完整纪念空间 · \(price)", "Unlock Full Plan · \(price)")
    }

    var tierFreeFeatures: [String] {
        t(["主照片", "首页星球观察窗", "TA的故事", "相册最多 9 张", "H5分享", "访客抱抱", "查看抱抱记录"],
          ["Main photo", "Home planet window", "Their Story", "Up to 9 album photos", "Share page", "Visitor hugs", "Hug records"])
    }
    var tierPaidFeatures: [String] {
        t(["包含免费档全部内容", "相册最多 50 张照片", "天堂信箱（私密写信）", "更完整的保存感"],
          ["Everything in Free Plan", "Up to 50 album photos", "Letters to Them (private)", "A fuller way to keep them close"])
    }
    var tierFutureFeatures: [String] {
        t(["视频回忆", "周年提醒", "更高级纪念视觉"],
          ["Video memories", "Anniversary reminders", "Premium visuals"])
    }

    // MARK: - Purchase Errors (PurchaseManager.PurchaseError)

    func purchaseErrorMessage(_ error: PurchaseManager.PurchaseError) -> String {
        switch error {
        case .productLoadFailed:
            return t("产品信息加载失败，请稍后再试。", "Product information couldn't load. Please try again later.")
        case .notSignedIn:
            return t("请先登录。", "Please sign in first.")
        case .verificationFailed:
            return t("购买验证未通过，请联系客服。", "Purchase verification failed. Please contact support.")
        case .purchaseFailed:
            return t("购买未能完成，请稍后重试。", "The purchase couldn't be completed. Please try again later.")
        case .noValidPurchase:
            return t("未找到有效的购买记录。", "No valid purchase was found.")
        }
    }

    // MARK: - Create Success

    var successTitle: String { t("星球已经为TA准备好了", "Their little planet is ready") }
    var successBodyPaid: String { t("完整纪念空间已开启，\n50 张相册和天堂信箱都在等TA。", "Full Memorial Space is now active.\n50 album photos and Letters to Them are ready.") }
    var successBodyFree: String { t("补充一点回忆后，\n可以分享给也记得TA的人。", "Once you've added some memories,\nyou can share with others who remember them.") }
    var successContinueBtn: String { t("继续补充回忆", "Add memories") }
    var successViewBtn: String     { t("去看看TA", "Go see them") }

    // MARK: - Home (Unboarded)

    var homeUnboardedTitle: String { t("还没有为TA创建星球", "No little planet yet") }
    var homeUnboardedBody: String  { t("先留下TA的名字和一张照片，故事和回忆可以之后慢慢补充。", "Start with a name and photo — more memories can come later.") }

    // MARK: - Learn More Sheet

    var learnMoreTitle: String        { t("关于留光", "About Pawlight") }
    var learnMoreItem1Title: String   { t("一个安静的地方", "A gentle place") }
    var learnMoreItem1Detail: String  { t("不是说说，不是动态。只是一个你可以随时回来、静静想念TA的空间。", "Not a post. Not a feed. Just a quiet space you can return to whenever you miss them.") }
    var learnMoreItem2Title: String   { t("留下TA的样子", "Keep their story") }
    var learnMoreItem2Detail: String  { t("上传照片、写下TA的故事和纪念语——只属于你和TA。", "Photos, their story, and a note for them — just for you.") }
    var learnMoreItem3Title: String   { t("分享给也记得TA的人", "Share with those who remember") }
    var learnMoreItem3Detail: String  { t("把纪念页分享给家人或朋友，让他们也能来看看，留下抱抱。", "Share with family or friends so they can visit and leave a hug.") }
    var learnMoreOk: String           { t("好，我知道了", "Got it") }

    // MARK: - Home (Created)

    var homeSentencePlaceholder: String { t("写一句想留给TA的话", "Add a note for them") }
    var homeTapHint: String             { t("轻触，看看TA的回忆", "Tap to see their memories") }
    var hugReminderHasNewTitle: String  { t("有人也来看看TA", "Someone stopped by") }
    var hugReminderNoNewTitle: String   { t("最近有人抱抱了TA", "Someone sent a hug recently") }
    var hugReminderNoNewBody: String    { t("有人也来看看TA，轻轻抱抱了TA。", "They came to visit and sent a gentle hug.") }
    func hugReminderNewCount(_ n: Int) -> String {
        t("收到了 \(n) 个抱抱", n == 1 ? "1 hug received" : "\(n) hugs received")
    }
    var quickActionStory: String  { t("写故事", "Story") }
    var quickActionPhotos: String { t("放照片", "Photos") }
    var quickActionShare: String  { t("分享", "Share") }
    var memoryStatusTitle: String      { t("最近的回忆", "Recent memories") }
    var memoryStatusEmptyTitle: String { t("可以先留下一点回忆", "Start with a memory") }
    var memoryStatusAddMore: String    { t("继续补充", "Add more") }
    var memoryStatusEmptyBody: String  { t("写下一件关于TA的小事，或放一张最想留下的照片。", "Write something about them, or add a photo you'd love to keep.") }
    func memoryStatusBodyStoryOnly(_ n: Int) -> String {
        t("已经留下了 1 段故事。\n可以再放一张和TA有关的照片。",
          "You've written their story.\nYou could also add a photo.")
    }
    func memoryStatusBodyPhotosOnly(_ n: Int) -> String {
        t("已经留下了 \(n) 张照片。\n可以再写下一点关于TA的故事。",
          "You've added \(n == 1 ? "1 photo" : "\(n) photos").\nYou could also write their story.")
    }
    func memoryStatusBodyBoth(_ n: Int) -> String {
        t("已经留下了 1 段故事、\(n) 张照片。\n继续慢慢补充关于TA的回忆。",
          "You've written their story and added \(n == 1 ? "1 photo" : "\(n) photos").\nKeep adding memories over time.")
    }
    var freeUpgradePhotoFullTitle: String { t("照片已到免费上限", "Photo limit reached") }
    var freeUpgradeMoreTitle: String      { t("想保存更多照片时", "Save more photos?") }
    var freeUpgradePhotoFullBody: String  { t("完整纪念空间可以保存更多和TA有关的瞬间。", "Full Memorial Space lets you keep more moments with them.") }
    var freeUpgradeMoreBody: String       { t("完整纪念空间可以留下更多照片，\n也可以使用天堂信箱。", "Full Memorial Space includes more photos\nand Letters to Them.") }

    // MARK: - Scene Portrait (AI 场景画像/动态观察窗, 付费功能)

    var scenePortraitEntryBtn: String     { t("为TA画一个场景", "Paint a scene for them") }
    var scenePortraitRevertBtn: String    { t("↺ 切回照片", "↺ Back to photo") }
    var scenePortraitReverting: String    { t("切回中…", "Switching back…") }
    var scenePortraitInputTitle: String   { t("想看到 TA 在什么样的地方？", "Where would you love to see them?") }
    var scenePortraitInputBody: String    { t("写下一个场景，我们把 TA 画进去", "Describe a scene, and we'll paint them into it") }
    var scenePortraitInputPlaceholder: String { t("比如：在洒满阳光的窗台上打盹", "e.g. dozing on a sunlit windowsill") }
    var scenePortraitGenerateBtn: String  { t("生成画像", "Paint their portrait") }
    var scenePortraitPickTitle: String    { t("选一张最像 TA 的", "Choose the one that looks most like them") }
    var scenePortraitPickBody: String     { t("轻点一张，把它带进星球观察窗", "Tap one to bring it into the planet window") }
    var scenePortraitGeneratingImage: String { t("正在为 TA 绘制画像…", "Painting their portrait…") }
    var scenePortraitGeneratingVideo: String { t("画面正在慢慢成形…", "The scene is gently taking shape…") }

    // MARK: - Memory View

    var memoryUnboardedTitle: String    { t("还没有为TA创建星球", "No little planet yet") }
    var memoryUnboardedBody: String     { t("先留下TA的名字和一张照片，之后再慢慢补充回忆。", "Start with a name and photo — memories can come later.") }
    var memorySectionStory: String      { t("TA的故事", "Their Story") }
    var memorySectionPhotos: String     { t("照片回忆", "Photos") }
    var memorySectionMailbox: String    { t("天堂信箱", "Letters to Them") }
    var memorySectionHugs: String       { t("抱抱记录", "Hugs") }
    var memoryLockedBadge: String       { t("已锁定", "Locked") }
    var memorySentencePlaceholder: String { t("写一句想留给TA的话", "Add a note for them") }
    var memoryStoryEmpty: String    { t("还没有写下TA的故事。\n可以从第一次见到TA，或者最想念TA的一件小事开始。", "No story yet.\nYou could start with the first time you met, or a small moment you miss most.") }
    var memoryWriteStory: String    { t("写下TA的故事", "Write their story") }
    var memoryPhotosEmpty: String   { t("还没有添加照片。\n可以先放一张和TA有关的瞬间。", "No photos yet.\nStart with a photo you'd love to keep.") }
    var memoryAddPhotos: String     { t("添加照片", "Add photos") }
    func memoryPhotoCount(_ n: Int, _ limit: Int) -> String { t("已保存 \(n) / \(limit) 张", "\(n) / \(limit) photos") }
    var memoryMailboxEmpty: String  { t("想说的话，可以慢慢写在这里。\n这些信只给主人自己看。", "You can write whatever's on your mind here.\nThese letters are just for you.") }
    var memoryMailboxLocked: String { t("有些话，不一定要放在纪念页里。\n开启完整纪念空间后，可以把想对TA说的话留在这里，只有你自己可以看到。", "Some things don't need to be on the memorial page.\nWith Full Memorial Space, you can leave private letters here — just for you.") }
    var memoryHugsEmpty: String     { t("还没有收到抱抱。\n分享给也记得TA的人，他们可以轻轻抱抱TA。", "No hugs yet.\nShare with people who remember them — they can send a gentle hug.") }
    func memoryNewHugs(_ n: Int) -> String { t("有 \(n) 个新的抱抱", n == 1 ? "1 new hug" : "\(n) new hugs") }
    func memoryHugsTotal(_ n: Int) -> String { t("已经有 \(n) 位朋友轻轻抱过TA", n == 1 ? "1 person has sent a gentle hug" : "\(n) people have sent a gentle hug") }
    var memoryShareCardTitle: String        { t("分享给也记得TA的人", "Share with those who remember") }
    var memoryShareCardNoContent: String    { t("补充一点回忆后，也可以分享给记得TA的人", "Add some memories first, then share with those who remember") }
    var memoryShareCardSubtitle: String     { t("他们可以看看TA，也轻轻抱抱TA。", "They can visit and send a gentle hug.") }
    var memoryShareCardSubtitleEmpty: String { t("先写下一点故事或放一张照片，\n会让纪念页更完整。", "Adding a story or photo will make the memorial page more complete.") }
    var memoryShareBtn: String              { t("分享纪念页", "Share memorial page") }
    var memorySharePrivacyAlertTitle: String { t("需要调整分享设置", "Adjust share settings") }
    var memorySharePrivacyAlertBody: String  { t("当前设置为仅自己可见，分享前需要改为通过链接可见。", "This is currently private. Make it visible by link before sharing.") }
    var memorySharePrivacyConfirmBtn: String { t("进入分享设置", "Go to settings") }
    func memoryLetterCount(_ n: Int) -> String { t("共 \(n) 封信", n == 1 ? "1 letter" : "\(n) letters") }
    var memoryLetterDefaultTitle: String    { t("写给TA的一封信", "A letter to them") }

    // MARK: - Story Edit

    var storyNavTitle: String     { t("TA的故事", "Their Story") }
    var storyFirstTimeBody: String { t("写下你记得的TA。\n可以是一件小事，一个习惯，或者第一次见到TA的那天。", "Write what you remember.\nA small moment, a habit, or the first day you met.") }
    var storyReturningBody: String { t("你可以继续补充这段故事，或者改成现在更想留下的样子。", "You can keep adding to this story, or rewrite it the way you want it now.") }
    var storyPrompt1: String { t("第一次见到TA", "The first time we met") }
    var storyPrompt2: String { t("TA的小习惯", "Their little habits") }
    var storyPrompt3: String { t("最想念的一件事", "The thing I miss most") }
    var storyPrompt4: String { t("TA陪伴我的一天", "A day they were with me") }
    var storyPlaceholder: String { t("比如：第一次见到TA的时候，\n它还很小。\n后来它最喜欢趴在窗边晒太阳……", "e.g. The first time I saw them, they were so small.\nThey loved lying in the window in the sun...") }
    var storyOverLimit: String    { t("故事有点长了，可以稍微精简一点。", "The story is a bit long — you might want to trim it a little.") }
    var storySaveError: String    { t("故事暂时没有保存成功，请稍后再试。", "Couldn't save — please try again.") }
    var storyPublicNotice: String { t("这段故事会留在TA的纪念主页里。\n分享纪念页时，也记得TA的人可以看到。", "This story will appear on their memorial page.\nPeople you share it with will be able to see it.") }
    var storyUnsavedTitle: String { t("你还没有保存故事", "Story not saved") }
    var storyUnsavedBody: String  { t("你还没有保存你的故事，确认要退出吗？", "You haven't saved your story yet. Are you sure you want to leave?") }
    var storyClearTitle: String   { t("要清空TA的故事吗？", "Clear their story?") }
    var storyClearBody: String    { t("清空后，回忆页和分享出去的纪念页将不再展示这段故事。", "This will remove the story from the memory page and any shared pages.") }
    var storyClearBtn: String     { t("清空故事", "Clear story") }
    var storyConfirmExit: String  { t("确认退出", "Leave") }

    // MARK: - Memorial Sentence Edit

    var memorialPlaceholder: String     { t("愿你在有风和阳光的地方……", "May you be somewhere with wind and sunshine...") }
    var memorialUnsavedTitle: String    { t("你还没有保存纪念语", "Note not saved") }
    var memorialUnsavedBody: String     { t("你还没有保存这句纪念语，确认要退出吗？", "You haven't saved this note yet. Are you sure you want to leave?") }
    var memorialSaveErrorBody: String   { t("纪念语暂时没有保存成功，请稍后再试。", "Couldn't save — please try again.") }

    // MARK: - Album View

    var albumNavTitle: String   { t("照片回忆", "Photos") }
    var albumAddPhotoBtn: String { t("添加照片", "Add photos") }
    var albumAddFirstBtn: String { t("添加第一张照片", "Add first photo") }
    var albumAddMore: String     { t("继续添加", "Add more") }
    var albumEmptyTitle: String  { t("把和TA有关的瞬间\n慢慢放在这里", "Slowly fill this with\nmoments of them") }
    var albumEmptyBody: String   { t("可以先从一张最想留下的照片开始。", "Start with a photo you'd love to keep.") }
    var albumEmptyNote: String   { t("主照片会陪TA出现在星球里，\n这里可以继续放下更多和TA有关的瞬间。", "The main photo stays with their keepsake — add more moments here.") }
    var albumUploadingLabel: String { t("正在放进\n回忆里…", "Saving to\nmemories...") }
    var albumPublicNotice: String   { t("这些照片会出现在TA的纪念主页里。\n分享纪念页时，也记得TA的人可以看到。", "These photos will appear on their memorial page.\nPeople you share it with will be able to see them.") }
    var albumAtLimitPaid: String { t("已满", "Full") }
    var albumAtLimitFree: String { t("免费上限", "Free limit") }
    func albumCapacity(_ n: Int, _ limit: Int) -> String { t("已保存 \(n) / \(limit) 张", "\(n) / \(limit) saved") }
    func albumOverLimitTitle(_ selected: Int, _ available: Int) -> String { t("照片数量超出上限", "Too many photos selected") }
    func albumOverLimitBody(_ selected: Int, _ available: Int) -> String {
        t("你选择了 \(selected) 张照片，但目前只能再保存 \(available) 张。",
          "You selected \(selected) photos but can only save \(available) more.")
    }
    func albumUploadPartialBtn(_ n: Int) -> String { t("仅上传前 \(n) 张", "Upload first \(n)") }
    func albumSuccessMsg(_ n: Int) -> String {
        n == 1 ? t("照片已放进回忆里。", "Photo added to memories.")
               : t("\(n) 张照片已放进回忆里。", "\(n) photos added to memories.")
    }
    func albumPartialMsg(_ ok: Int, _ fail: Int) -> String {
        t("保存了 \(ok) 张，\(fail) 张暂时没能保存。", "\(ok) saved, \(fail) couldn't be saved.")
    }
    var albumAllFailedMsg: String  { t("照片暂时没能保存，请重新试一次。", "Photos couldn't be saved — please try again.") }
    var albumFormatErrorMsg: String { t("暂时只支持图片上传，视频会在后续版本支持。", "Only images are supported for now — video support is coming.") }
    func limitSheetBody(_ isPaid: Bool, _ limit: Int) -> String {
        isPaid ? t("当前照片数量已达上限。", "You've reached the photo limit.")
               : t("免费纪念空间最多可保存 \(limit) 张照片。\n如果还想继续留下更多瞬间，可以了解完整纪念空间。",
                   "The free plan stores up to \(limit) photos.\nExplore the full plan to keep more.")
    }
    var limitSheetGotIt: String { t("知道了", "Got it") }

    // MARK: - Photo Detail

    var photoLoadError: String      { t("这张照片暂时没有加载出来", "This photo couldn't load") }
    var photoDeleteTitle: String    { t("要删除这张照片吗？", "Delete this photo?") }
    var photoDeleteBody: String     { t("删除后，这张照片将不再出现在TA的照片回忆和分享出去的纪念页中。", "This photo will be removed from their memories and any shared pages.") }
    var photoDeleteErrorTitle: String { t("删除失败", "Delete failed") }
    var photoDeleteErrorBody: String  { t("这张照片暂时没能删除，请稍后再试。", "This photo couldn't be deleted — please try again.") }

    // MARK: - Mailbox View

    var mailboxNavTitle: String      { t("天堂信箱", "Letters to Them") }
    var mailboxPrivacyHint: String   { t("这些信只给主人自己看。", "These letters are just for you.") }
    var mailboxHeroTitle: String     { t("把想说的话，\n安静地留在这里", "Leave the words you want to say,\nquietly here") }
    var mailboxHeroBody: String      { t("在这里，你可以写下想对它说的心里话，\n它会在另一个温暖的地方被安放。", "Write what you wish you could tell them.\nIt will stay here, held in a quiet, warm place.") }
    func mailboxLetterCount(_ n: Int) -> String { t("共 \(n) 封信", n == 1 ? "1 letter" : "\(n) letters") }
    var mailboxEmptyTitle: String    { t("还没有信件", "No letters yet") }
    var mailboxEmptyBody: String     { t("想说的话，不必着急整理好。想TA的时候，随时写下来。", "Write your first private letter when you're ready.") }
    var mailboxWriteFirstBtn: String { t("写第一封信", "Write first letter") }
    var mailboxLoadError: String     { t("信件暂时加载不出来", "Letters couldn't load") }
    var mailboxLoadErrorBody: String { t("可以稍后再试。", "You can try again later.") }
    var mailboxFooter: String        { t("思念会变成风，\n轻轻地陪伴着你。", "May the missing become a soft wind\nthat stays with you.") }
    var mailboxDefaultTitle: String  { t("写给TA的一封信", "A letter to them") }

    // MARK: - Letter Edit

    var letterEditNavTitle: String    { t("写给TA", "To them") }
    var letterEditTitleLabel: String  { t("这封信的名字，可选", "Title (optional)") }
    var letterEditTitlePlaceholder: String { t("给这封信起个名字", "Name this letter") }
    var letterEditPromptsLabel: String     { t("可以从这里开始", "You could start with") }
    var letterEditPrompt1: String          { t("今天想对TA说的话", "What I want to say today") }
    var letterEditPrompt2: String          { t("突然想起的一件小事", "Something I just remembered") }
    var letterEditPrompt3: String          { t("没有来得及说出口的", "What I never got to say") }
    var letterEditContentPlaceholder: String { t("想对TA说的话，慢慢写在这里……", "Write whatever you'd like to say to them...") }
    var letterEditOverLimit: String          { t("内容超出限制", "Over the limit") }
    var letterEditSaveError: String          { t("这封信暂时没有保存成功，请稍后再试。", "Couldn't save — please try again.") }
    var letterEditPrivacyNotice: String      { t("这封信只会留在天堂信箱里，不会出现在分享出去的纪念页中。", "This letter stays private in Letters to Them and will not appear on the shared memorial page.") }
    var letterEditDeleteBtn: String          { t("删除这封信", "Delete this letter") }
    var letterEditDeletingBtn: String        { t("删除中……", "Deleting...") }
    func letterEditUnsavedTitle(_ isNew: Bool) -> String { isNew ? t("这封信还没有保存", "Letter not saved") : t("修改还没有保存", "Changes not saved") }
    func letterEditUnsavedBody(_ isNew: Bool) -> String { isNew ? t("现在离开的话，内容不会保留。", "If you leave, the content won't be saved.") : t("现在离开的话，本次修改不会保留。", "If you leave, your changes won't be saved.") }
    var letterEditDeleteAlertTitle: String   { t("确定要删除这封信吗？", "Delete this letter?") }
    var letterEditDeleteAlertBody: String    { t("删除后，这封信将无法恢复。", "Once deleted, it can't be recovered.") }
    var letterEditDeleteErrorTitle: String   { t("删除失败", "Delete failed") }
    var letterEditDeleteErrorBody: String    { t("这封信暂时没能删除，请稍后再试。", "This letter couldn't be deleted — please try again.") }

    // MARK: - Letter Detail

    var letterDetailNavTitle: String  { t("天堂信箱", "Letters to Them") }
    var letterDetailDefaultTitle: String { t("写给TA的一封信", "A letter to them") }
    var letterDetailPrivacy: String   { t("这封信只会留在天堂信箱里，不会出现在分享出去的纪念页中。", "This letter stays private in Letters to Them and will not appear on the shared memorial page.") }

    func letterWrittenOn(_ date: Date) -> String {
        let cal = Calendar(identifier: .gregorian)
        let y = cal.component(.year, from: date)
        let m = cal.component(.month, from: date)
        let d = cal.component(.day, from: date)
        if l == .zh { return "写于\(y)年\(m)月\(d)日" }
        let fmt = DateFormatter(); fmt.dateFormat = "MMMM d, yyyy"
        return "Written on \(fmt.string(from: date))"
    }
    func letterEditedOn(_ date: Date) -> String {
        if l == .zh {
            let cal = Calendar(identifier: .gregorian)
            let y = cal.component(.year, from: date)
            let m = cal.component(.month, from: date)
            let d = cal.component(.day, from: date)
            return "最后编辑于\(y)年\(m)月\(d)日"
        }
        let fmt = DateFormatter(); fmt.dateFormat = "MMMM d, yyyy"
        return "Last edited \(fmt.string(from: date))"
    }

    // MARK: - Mailbox Locked

    var mailboxLockedTitle: String    { t("天堂信箱", "Letters to Them") }
    var mailboxLockedBody: String     { t("有些话，不一定要放在纪念页里。\n开启后，可以把想对TA说的话慢慢写在这里，\n只有你自己可以看到。", "Some things don't need to be on the memorial page.\nWith this, you can write privately to them — just for you to see.") }
    var mailboxLockedPrivacyHint: String { t("这些信不会展示在分享出去的纪念页中，\n也不会被访客看到。", "These letters won't appear on the shared memorial page\nor be visible to visitors.") }
    var mailboxLockedEntitlementTitle: String { t("完整纪念空间包含", "Full Memorial Space includes") }
    var mailboxLockedMailboxTitle: String    { t("天堂信箱", "Letters to Them") }
    var mailboxLockedMailboxSubtitle: String { t("只属于你和TA的私密信件空间", "A private space just for you and them") }
    var mailboxLockedPhotosTitle: String    { t("更多照片", "More photos") }
    var mailboxLockedPhotosSubtitle: String { t("相册容量从 9 张提升至 50 张", "Album expands from 9 to 50 photos") }
    var mailboxLockedMoreTitle: String      { t("更多权益", "More benefits") }
    var mailboxLockedMoreSubtitle: String   { t("后续将解锁更多纪念空间专属能力", "More features coming in future updates") }
    var mailboxLockedLearnMoreBtn: String   { t("了解完整纪念空间", "Explore the full plan") }

    // MARK: - Hugs View

    var hugsNavTitle: String    { t("抱抱记录", "Hugs") }
    var hugsEmptyTitle: String  { t("还没有抱抱记录", "No hugs yet") }
    var hugsEmptyBody: String   { t("把纪念页分享给也记得TA的人，\n他们可以轻轻抱抱TA。", "Share the memorial page with people who remember them —\nthey can send a gentle hug.") }
    func hugsCount(_ n: Int) -> String { t("共 \(n) 个抱抱", n == 1 ? "1 hug total" : "\(n) hugs total") }
    var hugsAnonymous: String { t("匿名访客", "Anonymous visitor") }
    var hugsAction: String    { t("轻轻抱了抱TA", "sent a gentle hug") }

    // MARK: - Mine View

    var mineTitle: String          { t("我的", "Me") }
    var minePetSection: String     { t("我的宠物", "My Pet") }
    var mineAddPet: String         { t("新增宠物", "Add another pet") }
    var mineAddPetSoon: String     { t("即将开放", "Coming soon") }
    var mineEntitlementSection: String { t("纪念空间", "Memorial Space") }
    var minePaidLabel: String      { t("完整纪念空间（已开通）", "Full Memorial Space (active)") }
    var mineFreeLabel: String      { t("权益与升级", "Plan & Benefits") }
    var minePrivacyLabel: String   { t("权限设置", "Privacy Settings") }
    var mineSupportSection: String { t("支持", "Support") }
    var mineLanguageSection: String { t("语言 / Language", "Language / 语言") }
    var mineFeedbackLabel: String  { t("客服与反馈", "Support & Feedback") }
    var mineTermsLabel: String     { t("用户协议", "Terms of Service") }
    var minePrivacyPolicyLabel: String { t("隐私政策", "Privacy Policy") }
    var mineDeleteAccountLabel: String { t("删除账号", "Delete Account") }
    var mineDeleteAlertTitle: String   { t("删除账号", "Delete Account") }
    var mineDeleteAlertBody: String    { t("删除账号将永久清除TA的纪念空间、照片、信件和抱抱记录，且无法恢复。", "Deleting your account will permanently erase your pet's memorial space, photos, letters, and hugs. This cannot be undone.") }
    var mineDeleteConfirmBtn: String   { t("确认删除", "Delete") }
    var mineDeleteErrorTitle: String   { t("删除失败", "Delete failed") }
    var mineDeleteErrorBody: String    { t("账号暂时没能删除，请检查网络后重试。", "Your account couldn't be deleted — please check your connection and try again.") }
    var mineUnboardedTitle: String     { t("还没有创建TA的星球", "No little planet yet") }
    var mineUnboardedBody: String      { t("创建后，这里可以查看\n权益、账号和宠物设置。", "Once you create one, you can manage\nyour plan, account, and pet settings here.") }
    var mineAppleLogin: String         { t("Apple 账号登录", "Signed in with Apple") }
    var mineBottomLine1: String        { t("回忆不在远方，", "Memories are not far away —") }
    var mineBottomLine2: String        { t("它一直在这里。", "they've been here all along.") }
    func mineVersion(_ v: String) -> String     { t("版本 \(v)", "Version \(v)") }
    func mineVersionDebug(_ v: String) -> String { t("版本 \(v)（测试版）", "Version \(v) (Debug)") }

    // MARK: - Share Panel

    var sharePanelNavTitle: String        { t("分享纪念页", "Share memorial page") }
    var sharePanelPreviewSubtitle: String { t("的纪念星球", "'s memorial keepsake") }
    var sharePanelVisibilityTitle: String { t("谁可以看见TA", "Who can see this?") }
    var sharePanelVisibilityLink: String  { t("通过链接可见", "Visible by link") }
    var sharePanelVisibilityPrivate: String { t("仅自己可见", "Only me") }
    var sharePanelHugTitle: String    { t("允许访客抱抱TA", "Allow visitor hugs") }
    var sharePanelHugSubtitle: String { t("访客可以用抱抱表达心意", "Visitors can send a hug") }
    var sharePanelCopyBtn: String    { t("复制链接", "Copy link") }
    var sharePanelCopiedBtn: String  { t("已复制", "Copied!") }
    var sharePanelShareBtn: String   { t("分享给好友", "Share with friends") }
    var sharePanelPrivacyAlertTitle: String { t("改为链接可见", "Make visible by link") }
    var sharePanelPrivacyAlertBody: String  { t("当前设置为仅自己可见。分享前需要改为通过链接可见，确认吗？", "This is currently private. Make it visible by link before sharing. Confirm?") }
    var sharePanelPrivacyConfirmBtn: String { t("确认改为链接可见", "Make visible by link") }
    var sharePanelSaveErrorTitle: String    { t("设置失败", "Save failed") }
    var sharePanelSaveErrorBody: String     { t("暂时没有改成功，请稍后再试。链接尚未送出。", "Couldn't save — please try again. The link wasn't sent.") }

    // MARK: - Entitlement View

    var entitlementNavTitle: String    { t("纪念空间", "Memorial Space") }
    var entitlementSelectTitle: String { t("选择适合TA的纪念空间", "Choose a plan for them") }
    var entitlementPaidTitle: String   { t("完整纪念空间已开启", "Full Memorial Space is active") }
    var entitlementRestoreBtn: String  { t("恢复购买", "Restore purchase") }
    var entitlementErrorTitle: String  { t("购买未完成", "Purchase not completed") }
    var entitlementFeatureMainPhoto: String  { t("主照片 + 首页星球观察窗", "Main photo + home planet window") }
    var entitlementFeatureStory: String      { t("TA的故事", "Their Story") }
    var entitlementFeaturePhotos: String     { t("相册照片", "Album photos") }
    var entitlementFeaturePhotosFree: String { t("最多 9 张", "Up to 9") }
    var entitlementFeaturePhotosPaid: String { t("最多 50 张", "Up to 50") }
    var entitlementFeatureShare: String      { t("H5 分享 + 访客抱抱", "Share page + visitor hugs") }
    var entitlementFeatureHugRecord: String  { t("抱抱记录", "Hug records") }
    var entitlementFeatureMailbox: String    { t("天堂信箱", "Letters to Them") }

    // MARK: - Pet Profile

    var petProfileNavTitle: String       { t("宠物资料", "Pet Profile") }
    var petProfileBasicSection: String   { t("基础信息", "Basic Info") }
    var petProfileNameField: String      { t("名字", "Name") }
    var petProfileTypeField: String      { t("类型", "Type") }
    var petProfileDatesSection: String   { t("日期（选填）", "Dates (optional)") }
    var petProfileArrivalDate: String    { t("来到身边", "Date they came home") }
    var petProfileBirthDate: String      { t("生日", "Birthday") }
    var petProfileLeftDate: String       { t("离开日期", "Date they left") }
    var petProfileNotFilled: String      { t("未填写", "Not set") }
    var petProfileSaveError: String      { t("宠物资料暂时没有保存成功，请稍后再试。", "Couldn't save — please try again.") }

    // MARK: - Privacy Settings

    var privacyNavTitle: String          { t("权限设置", "Privacy Settings") }
    var privacyVisibilitySection: String { t("谁可以看见TA", "Who can see them?") }
    var privacyVisibilityLabel: String   { t("可见范围", "Visibility") }
    var privacyVisibilityLink: String    { t("通过链接可见", "Visible by link") }
    var privacyVisibilityPrivate: String { t("仅自己可见", "Only me") }
    var privacyHugToggle: String         { t("允许访客抱抱TA", "Allow visitor hugs") }
    var privacyHugFooter: String         { t("关闭后，H5 页面仍可访问，但访客无法发起抱抱。", "If turned off, the page is still accessible but visitors can't send hugs.") }
    var privacySaveError: String         { t("权限设置暂时没有保存成功，请稍后再试。", "Couldn't save — please try again.") }

    // MARK: - Memory Header date formatting

    func yearLabel(_ year: String) -> String { l == .zh ? "\(year)年" : year }
    func arrivedLabel(_ year: String) -> String { l == .zh ? "\(year)来到" : "came home on \(year)" }
    func leftLabel(_ year: String) -> String    { l == .zh ? "\(year)离开" : "left on \(year)" }

    // MARK: - Private helper

    private func t(_ zh: [String], _ en: [String]) -> [String] { l == .zh ? zh : en }
}
