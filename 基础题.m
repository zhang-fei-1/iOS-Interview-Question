/******************************这些题目是平时上网看到的，答案是自己从网上查找的，作为笔记学习而已****************************************/
test
1，下面的代码输出什么？

   @implementation Son : Father
     - (id)init
     {
         self = [super init];
         if (self) {
             NSLog(@"%@", NSStringFromClass([self class]));
             NSLog(@"%@", NSStringFromClass([super class]));
         }
         return self;
     }
   @end

     都输出 Son

self 和 super 的区别：
	
	self 是类的隐藏参数，指向当前调用方法的这个类的实例；

	super 是一个 Magic Keyword， 它本质是一个编译器标示符，和 self 是指向的同一个消息接受者！

	他们两个的不同点在于：super 会告诉编译器，调用 class 这个方法时，要去父类的方法，而不是本类里的。

上面的例子不管调用[self class]还是[super class]，接受消息的对象都是当前 Son ＊xxx 这个对象。

	调用 [self class] 会转化成 objc_msgSend函数：  id objc_msgSend(id self, SEL op, ...);第一个参数把self 传进去

	而调用 [super class] 时会转化成 objc_msgSendSuper函数： id objc_msgSendSuper(struct objc_super *super, SEL op, ...)

		第一个参数是 objc_super 这样一个结构体：

			struct objc_super {
			      __unsafe_unretained id receiver;
			      __unsafe_unretained Class super_class;
			};

			这个结构体有两个成员，第一个是 receiver ，类似于objc_msgSend函数第一个参数self ；第二个参数是记录当前类的父类是什么；

	执行[super class] 时会分两步进行：第一步先构造 objc_super 结构体；结构体第一个成员就是 self ； 第二个成员是 (id)class_getSuperclass(objc_getClass(“Son”)) , 实际该函数输出结果为 Father

				第二步回去Father这个类里面去找 - (Class)class 这个函数，没有找到然后去NSObject类里面去找，找到了。最后内部是使用 objc_msgSend(objc_super->receiver, @selector(class))去调用。

				此时已经和[self class]调用相同了，故上述输出结果仍然返回 Son；

2，runtime如何通过selector找到对应的IMP地址？（分别考虑类方法和实例方法）
	
	每一个类对象中都一个方法列表,方法列表中记录着方法的名称,方法实现,以及参数类型,其实selector本质就是方法名称,通过这个方法名称就可以在方法列表中找到对应的方法实现

3，objc中的类方法和实例方法有什么本质区别和联系？

 	类方法：

		类方法是属于类对象的
		
		类方法只能通过类对象调用
		
		类方法中的self是类对象.
		
		类方法可以调用其他的类方法
		
		类方法中不能访问成员变量
		
		类方法中不能直接调用对象方法
	
	实例方法：

		实例方法是属于实例对象的
	
		实例方法只能通过实例对象调用
	
		实例方法中的self是实例对象.
	
		实例方法中可以访问成员变量
	
		实例方法中直接调用实例方法
	
		实例方法中也可以调用类方法 通过类名

4，_objc_msgForward函数是做什么的，直接调用它将会发生什么？
	
	_objc_msgForward是 IMP 类型，用于消息转发的：当向一个对象发送一条消息，但它并没有实现的时候，_objc_msgForward会尝试做消息转发。

	消息调用流程：

		1.调用resolveInstanceMethod:方法 (或 resolveClassMethod:)。允许用户在此时为该 Class 动态添加实现。如果有实现了，则调用并返回YES，那么重新开始objc_msgSend流程。这一次对象会响应这个选择器，一般是因为它已经调用过class_addMethod。如果仍没实现，继续下面的动作。

		2.调用forwardingTargetForSelector:方法，尝试找到一个能响应该消息的对象。如果获取到，则直接把消息转发给它，返回非 nil 对象。否则返回 nil ，继续下面的动作。注意，这里不要返回 self ，否则会形成死循环。

		3.调用methodSignatureForSelector:方法，尝试获得一个方法签名。如果获取不到，则直接调用doesNotRecognizeSelector抛出异常。如果能获取，则返回非nil：创建一个 NSlnvocation 并传给forwardInvocation:。

		4.调用forwardInvocation:方法，将第3步获取到的方法签名包装成 Invocation 传入，如何处理就在这里面了，并返回非ni。

		5.调用doesNotRecognizeSelector: ，默认的实现是抛出异常。如果第3步没能获得一个方法签名，执行该步骤。

	_objc_msgForward在进行消息转发的过程中会涉及以下这几个方法：

		resolveInstanceMethod:方法 (或 resolveClassMethod:)。

		forwardingTargetForSelector:方法

		methodSignatureForSelector:方法

		forwardInvocation:方法

		doesNotRecognizeSelector: 方法

	直接调用_objc_msgForward是非常危险的事，如果用不好会直接导致程序Crash，但是如果用得好，能做很多非常酷的事。

5，runtime如何实现weak变量的自动置nil？

	runtime 对注册的类， 会进行布局，对于 weak 对象会放入一个 hash 表中。 

	用 weak 指向的对象内存地址作为 key，当此对象的引用计数为0的时候会 dealloc，

	假如 weak 指向的对象内存地址是a，那么就会以a为键， 在这个 weak 表中搜索，找到所有以a为键的 weak 对象，从而设置为 nil。

6，能否向编译后得到的类中增加实例变量？能否向运行时创建的类中添加实例变量？为什么？

	不能向编译后得到的类中增加实例变量；
	
	能向运行时创建的类中添加实例变量；

	因为编译后的类已经注册在 runtime 中，类结构体中的 objc_ivar_list 实例变量的链表 和 instance_size 实例变量的内存大小已经确定，

	同时runtime 会调用 class_setIvarLayout 或 class_setWeakIvarLayout 来处理 strong weak 引用。所以不能向存在的类中添加实例变量；

	运行时创建的类是可以添加实例变量，调用 class_addIvar 函数。但是得在调用 objc_allocateClassPair 之后，objc_registerClassPair 之前，原因同上。

在block内如何修改block外部变量？
	
	 默认情况下，在block中访问的外部变量是复制过去的，即：写操作不对原变量生效。但是你可以加上 __block 来让其写操作生效

	 Block不允许修改外部变量的值，这里所说的外部变量的值，指的是栈中指针的内存地址。__block 所起到的作用就是只要观察到该变量被 block 所持有，

	 就将“外部变量”在栈中的内存地址放到了堆中。进而在block内部也可以修改外部变量的值

7， NSCache 与 NSMutableDictionary 等集合类的区别或者说优势又是哪些呢？

	NSCache 类结合了各种自动删除策略，以确保不会占用过多的系统内存。如果其它应用需要内存时，系统自动执行这些策略。当调用这些策略时，会从缓存中删除一些对象，以最大限度减少内存的占用

	NSCache 是线程安全的，我们可以在不同的线程中添加、删除和查询缓存中的对象，而不需要锁定缓存区域

	不像 NSMutableDictionary 对象，NSCache 对象并不会拷贝键（key），而是会强引用它


/************************************ RunLoop *************************************************/
RunLoop ：
	
	RunLoop 实际上就是一个对象，这个对象管理了其需要处理的事件和消息，并提供了一个入口函数来执行循环事件的逻辑。

	线程执行了这个函数后，就会一直处于这个函数内部 "接受消息->等待->处理" 的循环中，直到这个循环结束（比如传入 quit 的消息），函数返回。

	OSX/iOS 系统中，提供了两个这样的对象：NSRunLoop 和 CFRunLoopRef

		CFRunLoopRef 是在 CoreFoundation 框架内的，它提供了纯 C 函数的 API，所有这些 API 都是线程安全的。

		NSRunLoop 是基于 CFRunLoopRef 的封装，提供了面向对象的 API，但是这些 API 不是线程安全的。

	RunLoop 与线程的关系：

		苹果不允许直接创建 RunLoop，它只提供了两个自动获取的函数：CFRunLoopGetMain() 和 CFRunLoopGetCurrent()

		主线程的runloop 默认是启动的；对于其他线程来说runloop 默认是没有启动的
		
		线程和 RunLoop 之间是一一对应的，其关系是保存在一个全局的 Dictionary 里。线程刚创建时并没有 RunLoop，如果你不主动获取，那它一直都不会有。

		RunLoop 的创建是发生在第一次获取时，RunLoop 的销毁是发生在线程结束时。你只能在一个线程的内部获取其 RunLoop（主线程除外）。

	CoreFoundation 里面关于 RunLoop 有5个类:
		
		CFRunLoopRef //就是RunLoop，提供CFRunLoopGetMain()和CFRunLoopGetCurrent()
		
		CFRunLoopModeRef //RunLoop运行模式
		
		CFRunLoopSourceRef //RunLoop里面内容 -- 事件源，输入源
		
		CFRunLoopTimerRef //RunLoop里面内容 -- 定时器
		
		CFRunLoopObserverRef //RunLoop里面内容 -- 观察者

		一个RunLoop里面可以有多个mode，每个mode又可以多个source，observer，timer。**可是每次RunLoop只能指定一个mode运行，如果想要切换mode，就必须先退出RunLoop

		，然后重新指定mode运行，这样做的目的就是避免mode之间相互影响

	RunLoop 的 mode 作用是什么？model 主要是用来指定事件在运行循环中的优先级

		分为：
			NSDefaultRunLoopMode（kCFRunLoopDefaultMode）：默认，空闲状态
			
			UITrackingRunLoopMode：ScrollView滑动时
			
			UIInitializationRunLoopMode：启动时
			
			NSRunLoopCommonModes（kCFRunLoopCommonModes）：Mode集合

		苹果公开提供的 Mode 有两个：

			NSDefaultRunLoopMode（kCFRunLoopDefaultMode）
			
			NSRunLoopCommonModes（kCFRunLoopCommonModes）

	以+ scheduledTimerWithTimeInterval...的方式触发的timer，在滑动页面上的列表时，timer会暂定回调，为什么？如何解决？

		RunLoop只能运行在一种mode下，如果要换mode，当前的loop也需要停下重启成新的。利用这个机制，

		ScrollView滚动过程中NSDefaultRunLoopMode（kCFRunLoopDefaultMode）的mode会切换到UITrackingRunLoopMode来保证ScrollView的流畅滑动：

		只能在NSDefaultRunLoopMode模式下处理的事件会影响ScrollView的滑动。如果我们把一个NSTimer对象以NSDefaultRunLoopMode（kCFRunLoopDefaultMode）

		添加到主运行循环中的时候, ScrollView滚动过程中会因为mode的切换，而导致NSTimer将不再被调度。

		解决方案：

			mode还是可定制的，所以：

			Timer计时会被scrollView的滑动影响的问题可以通过将timer添加到NSRunLoopCommonModes（kCFRunLoopCommonModes）来解决

	猜想runloop内部是如何实现的？

		一般来讲，一个线程一次只能执行一个任务，执行完成后线程就会退出。如果我们需要一个机制，让线程能随时处理事件但并不退出，通常的代码逻辑 是这样的：

		使用伪代码来展示下:

			// 
			// http://weibo.com/luohanchenyilong/ (微博@iOS程序犭袁)
			// https://github.com/ChenYilong
			
			int main(int argc, char * argv[]) {
			
			 //程序一直运行状态
			 while (AppIsRunning) {
			
			      //睡眠状态，等待唤醒事件
			      id whoWakesMe = SleepForWakingUp();
			
			      //得到唤醒事件
			      id event = GetEvent(whoWakesMe);
			
			      //开始处理事件
			      HandleEvent(event);
			
			 }
			
			 return 0;
			}



/************************************ UIApplication生命周期 *************************************************/

UIApplication生命周期的一些delegate方法:

	程序启动过程相关的一些delegate方法的调用时机如下：

		- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
		  
		  NSLog(@"程序启动完成：%s",__func__);
		  
		  return YES;
		}
		 
		- (void)applicationDidBecomeActive:(UIApplication *)application {
		  
		    NSLog(@"已经获得焦点：%s",__func__);
		}
		 
		- (void)applicationWillResignActive:(UIApplication *)application {
		  
		    NSLog(@"将要释放焦点：%s",__func__);
		}
		 
		- (void)applicationDidEnterBackground:(UIApplication *)application {
		  
		    NSLog(@"已经进入后台：%s",__func__);
		}
		 
		- (void)applicationWillEnterForeground:(UIApplication *)application {
		  
		    NSLog(@"将要进入前台：%s",__func__);
		}
		 
		- (void)applicationWillTerminate:(UIApplication *)application {
		  
		    NSLog(@"程序将要退出：%s",__func__);
		}

	情景1：程序启动：

		程序被加载到内存，完成启动，application对象会自动调用delegate的这个方法 didFinishLaunchingWithOptions:，证明程序已经启动完成。

		所以这个方法也是首先会被application回调的方法，且这个方法在整个程序的生命周期中只会被调用一次；该方法完成之后会调用 applicationDidBecomeActive：证明程序已经获得了焦点

		应用启动过程中，会依次调用delegate已经启动完成和已经获得焦点的方法，不会调用已经进入前台的方法。

	情景2：程序从前台退出后台：

		当程序处于前台时,单击home键，程序会自动退出到后台。在这个过程中，程序会先回调delegate的将要失去焦点的方法，证明程序将要失去焦点。

		- (void)applicationWillResignActive:(UIApplication *)application;

		调用调用完上面的方法后，程序紧接着会调用delegate已经进入后台的方法，证明程序已经进入后台。

		- (void)applicationDidEnterBackground:(UIApplication *)application;

		结论：单击home键进入后台会依次调用delegate的将要失去焦点的方法和已经进入后台的方法。

	情景3：程序从后台进入到前台

		从后台进入前台(无论是双击home键进入或者点击应用图标进入)，会回调delegate的将要进入前台方法，证明程序将要进入前台。

		- (void)applicationWillEnterForeground:(UIApplication *)application;

		回调完上面的方法，紧接着会继续回调delegate的已经获得焦点的方法，证明程序已经获得了焦点。

		- (void)applicationDidBecomeActive:(UIApplication *)application；

		结论：从后台进入前台，会依次调用delegate的将要进入前台和已经获得焦点的方法。

	情景4：双击home键切换程序

		在前台，双击home键，只会调用delegate的将要失去焦点的方法，证明程序将要失去焦点。

		- (void)applicationWillResignActive:(UIApplication *)application;

		当用户真正切换应用时候，才会继续调用delegate的已经进入后台的方法，证明程序已经进入后台。

		- (void)applicationDidEnterBackground:(UIApplication *)application;

		结论：双击home键切换应用。会分别调用程序将要失去焦点的方法和程序已经进入后台的方法。 且这两个方法是分开调用的。

		即，双击home键时调用将要失去焦点的方法，选择其他应用时调用已经进入后台的方法。

	情景5：在前台双击home键杀死程序

		双击home键时，只会调用delegate的将要失去焦点的方法（上面已经说过）,证明程序将要失去焦点。

		- (void)applicationWillResignActive:(UIApplication *)application;

		然后手指上滑杀死程序，会直接调用delegate的已经进入后台的方法，证明程序已经进入后台。

		- (void)applicationDidEnterBackground:(UIApplication *)application;

		然后紧接着调用delegate的程序将要退出的方法，证明程序将要被杀死。
		
		-(void)applicationWillTerminate:(UIApplication *)application;

	情景6：从其他程序前台双击home键杀死后台程序

		如果从其他程序的前台，双击home键杀死后台程序，被杀死程序只会回调delegate即将退出的方法。

		因为我们是从一个前台程序杀死一个后台程序，这个后台程序当初进入后台时候已经调用了将要释放焦点和已经进入后台的方法，

		所以杀死时候只会回调delegate即将终结的方法。

	情景7：下拉通知栏

		下拉通知栏，只会回调delegate的程序将要释放焦点的方法。程序并没有进入后台，所以不会调用进入后台的方法

		因为下拉通知栏只调用了将要释放焦点的方法，没有调用进入后台方法，所以收起通知栏时，只会调用已经获得焦点的方法，不会调用进入前台的方法。

		同样，从屏幕下方向上滑动屏幕，唤出工具栏时候，也只会调用delegate的将要释放焦点的方法。收起工具栏时，只会调用delegate的已经获得焦点的方法。

	
		注：如果一个应用程序失去焦点那么意味着用户当前无法进行交互操作，正因如此，程序从前台退出到后台时候，
			
			一般会先失去焦点再进入后台避免进入后台过程中用户还可以和程序进行交互。同理，一个应用程序从后台进入前台也是类似的，

			会先进入前台再获得焦点，这样进入前台过程中未完全准备好的情况下用户无法操作，保证了程序的安全性。


/************************************************ KVO KVC *******************************************/

    KVC :  Key-value coding 运用了一个isa-swizzling技术，它提供了一种使用字符串而不是访问器方法去访问一个对象实例变量的机制。

        isa-swizzling就是类型混合指针机制。KVC主要通过isa-swizzling，来实现其内部查找定位的；

        最要方法：

            - (id)valueForKey:(NSString *)key;

            - (void)setValue:(id)value forKey:(NSString *)key;

            - (id)valueForKeyPath:(NSString *)keyPath;

            -  (void)setValue:(id)value forKeyPath:(NSString *)keyPath;

            前边两个方法用到的Key较容易理解，就是要访问的属性名称对应的字符串。

            后面两个方法用到的KeyPath是一个被点操作符隔开的用于访问对象的指定属性的字符串序列

        实现原理：KVC再某种程度上提供了访问器的替代方案。不过访问器方法是一个很好的东西，以至于只要是有可能，
                
                KVC也尽量在访问器方法的帮助下工作。为了设置或者返回对象属性，KVC按顺序使用如下技术：
                
                ①检查是否存在-<key>、-is<key>（只针对布尔值有效）或者-get<key>的访问器方法，如果有可能，就是用这些方法返回值；
                
                    检查是否存在名为-set<key>:的方法，并使用它做设置值。对于-get<key>和-set<key>:方法，将大写Key字符串的第一个字母，并与Cocoa的方法命名保持一致；
                
                ②如果上述方法不可用，则检查名为-_<key>、-_is<key>（只针对布尔值有效）、-_get<key>和-_set<key>:方法；
                
                ③如果没有找到访问器方法，可以尝试直接访问实例变量。实例变量可以是名为：<key>或_<key>;
                
                ④如果仍为找到，则调用valueForUndefinedKey:和setValue:forUndefinedKey:方法。这些方法的默认实现都是抛出异常，我们可以根据需要重写它们。

    KVO : Key-value observing 翻译成键值观察。提供了一种当其它对象属性被修改的时候能通知当前对象的机制

        实现原理：当某个类的对象第一次被观察时，系统就会在运行期动态地创建该类的一个派生类，在这个派生类中重写基类中任何被观察属性的 setter 方法。派生类在被重写的 setter 方法实现真正的通知机制

        如果之前的类名为：Person，那么被runtime更改以后的类名会变成：NSKVONotifying_Person。新的NSKVONotifying_Person类会重写以下方法：增加了监听的属性对应的set方法，class，dealloc，_isKVOA

            ①class
            
                重写class方法是为了我们调用它的时候返回跟重写继承类之前同样的内容
            
            ②重写set方法新类会重写对应的set方法，是为了在set方法中增加另外两个方法的调用：- (void)willChangeValueForKey:(NSString *)key 或者 - (void)didChangeValueForKey:(NSString *)key,  其中，didChangeValueForKey:方法负责调用：- (void)observeValueForKeyPath: ofObject: change: context:这就是KVO实现的原理了！

总结一下，想使用KVO有三种方法：
    
    1)使用了KVC
    
        使用了KVC，如果有访问器方法，则运行时会在访问器方法中调用will/didChangeValueForKey:方法；
    
        没用访问器方法，运行时会在setValue:forKey方法中调用will/didChangeValueForKey:方法。
    
    2)有访问器方法
    
        运行时会重写访问器方法调用will/didChangeValueForKey:方法。
    
        因此，直接调用访问器方法改变属性值时，KVO也能监听到。
    
    3)显示调用will/didChangeValueForKey:方法。

如何手动触发一个value的KVO？
	
	自动触发 KVO 的原理：

		键值观察通知依赖于 NSObject 的两个方法: willChangeValueForKey: 和 didChangevlueForKey: 。

		在一个被观察属性发生改变之前， willChangeValueForKey: 一定会被调用，这就 会记录旧的值。

		而当改变发生后， observeValueForKey:ofObject:change:context: 会被调用，继而 didChangeValueForKey: 也会被调用。

		如果可以手动实现这些调用，就可以实现“手动触发”了。

/************************************************ UITableView复用 ***************************************/

// 返回第section组有多少行
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{}

// 返回每一行cell的样子
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{}

// 返回每行cell的高度
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{}

分析：系统会先调用numberOfSections获取每个section中有多少个cell；再获取每个cell的高度，计算所有cell的frame,就能计算下tableView的滚动范围；然后循环调用cellForRow和heightForRow，直到cell的个数充满当前屏幕。
    tableView:cellForRowAtIndexPath:方法调用的次数，取决于当前屏幕显示cell的个数，一开始只加载显示出来的cell，等有新的cell出现的时候会继续调用这个方法加载cell
    当新的cell出现的时候，首先从缓存池中获取，如果没有获取到，就自己创建cell。
    当有cell移除屏幕的时候，把cell放到缓存池中去。


/************************************* NSOperationQueue ************************************************/

NSOperation 和 GCD：其中 GCD 是基于 C 的底层的 API ，而 NSOperation 是对队列模型的高层级抽象，而且是基于GCD创建的。 

	虽然 NSOperation 是基于 GCD 实现的， 但是并不意味着它是一个 GCD 的 “dumbed-down” 版本， 

	相反，我们可以用NSOperation 轻易的实现一些 GCD 要写大量代码的事情。 因此， NSOperationQueue 是被推荐使用的， 

	除非你遇到了 NSOperationQueue 不能实现的问题。

	以下是 Operation Queues 和 Dispatch Queues 的不同：
		
		不遵循 FIFO（先进先出）：在 Operation Queues 中，你可以设置 operation（操作）的执行优先级，并且可以在 operation 之间添加依赖，这意味着你可以定义某些 operation，使得它们可以在另外一些 operation 执行完毕之后再被执行。这就是为什么它们不遵循先进先出的顺序。
		
		默认情况下 Operation Queues 是并发执行：虽然你不能将其改成串行队列，但还是有一种方法，通过在 operation 之间添加相依性来让 Operation Queues 中的任务按序执行。
		
		Operation Queues 是 NSOperationQueue 类的实例，任务被封装在 NSOperation 的实例中

	NSOperation:

		任务是以 NSOperation 实例的形式被提交到 Operation Queues 中去的。之前说过 GCD 中任务是以 block 的形式被提交
 
		NSOperation 是一个抽象类，不能直接使用，可以用他的子类 ：NSBlockOperation 和 NSInvocationOperation

			1，NSBlockOperation - 用这个类来初始化包含一个或多个 blocks 的 operation。该 operation 本身可包含的 block 超过一个，当所有的block 执行完毕后这个 operation 就被视为已完成。
			
			2，NSInvocationOperation - 用这个类来初始化一个 operation，能用来调用某指定对象的选择器（selector）

	优势:
		首先它可以通过 NSOperation 类的 addDependency（op: NSOperation）方法获得对相依性的支持

		可以设置 queuePriority 属性来改变执行的优先级

		可以取消掉某特定队列中的某个 operation，或者是取消队列中所有的 operation

			取消任何 operation 的时候，会是下面三种场景之一：
			
				你的 operation 已经完成了，这种情况下 cancel 方法没有任何效果。
			
				你的 operation 正在被执行的过程中，这种情况下系统不会强制停止你的 operation 代码，而是将 cancelled 属性置为 true。
			
				你的 operation 还在队列中等待被执行，这种情况下你的 operation 就不会被执行。

	NSOperation 有3个有用的布尔型属性：finished，cancelled 和 ready。

			finished 在 operation 执行完毕后被置为 true。
			
			cancelled 在 operation 被取消后被置为 true。

			ready 在 operation 即将被执行时被置为 true。

	所有的 NSOperation 在任务被完成后都可以选择去设置一段 completion block。NSOperation 的 finished 属性变为 true 后这段 block 就会被执行。

	例：

		var queue = NSOperationQueue()

		queue.addOperationWithBlock { () -> Void in
        
			//do something

		        NSOperationQueue.mainQueue().addOperationWithBlock({
		            
		            // configUI
		        })
		    }

		queue.addOperationWithBlock { () -> Void in

		        //do something
		        
		        NSOperationQueue.mainQueue().addOperationWithBlock({
		             
		             // configUI
		        })
		 
		    }

	或者：
		queue = NSOperationQueue()
		 
		let operation1 = NSBlockOperation(block: {
		
		let img1 = Downloader.downloadImageWithURL(imageURLs[0])
		
		NSOperationQueue.mainQueue().addOperationWithBlock({
			self.imageView1.image = img1
		        })
		    })
		    
		    operation1.completionBlock = {
		        print("Operation 1 completed")
		    }
		
		queue.addOperation(operation1)

/************************************************************新更( 5.6 )********************************************************************************************/

1,说一下frame与bounds的区别？
 	
 	frame: 该view在父view坐标系统中的位置和大小。（参照点是，父亲的坐标系统）
 	bounds：该view在本地坐标系统中的位置和大小。（参照点是，本地坐标系统，就相当于ViewB自己的坐标系统，以0,0点为起点）
 	center：该view的中心点在父view坐标系统中的位置和大小。（参照电是，父亲的坐标系统）

2,你是怎么理解深拷贝和浅拷贝的？
	
	容器类例如：NSArray，NSDictionary，NSSet 以及其对应的可变类
	
	对于所有系统容器类的copy或者mutableCopy方法，都是浅拷贝 

	注：在非集合类对象中：对 不可变 对象进行 copy 操作，是指针复制，mutableCopy 操作时内容复制；对 可变 对象进行 copy 和 mutableCopy 都是内容复制

		例： 
			[immutableObject copy] // 浅复制
			
			[immutableObject mutableCopy] //深复制
			
			[mutableObject copy] //深复制
			
			[mutableObject mutableCopy] //深复制
							
			但是：集合对象的内容复制仅限于对象本身，对象元素仍然是指针复制（浅拷贝）。

3，SDWebImgae 用什么方式判断gif/png图片的？
	
	+ (NSString *)sd_contentTypeForImageData:(NSData *)data;   SDWebImgae 为NSData写个分类，调用上述方法，可判断图片类型。

	根据二进制的数据获取图片的类型 ，每个文件头的第一个字节就能判断出是什么类型

	在方法后面写 __deprecated_msg （） 可以告诉开发者该方法不建议使用，括号里面是提示信息

4，Autorelease对象什么时候释放
	
	在没有手加Autorelease Pool的情况下，Autorelease对象是在当前的runloop迭代结束时释放的，而它能够释放的原因是系统在每个runloop迭代中都加入了自动释放池Push和Pop

	Autorelease原理：

		AutoreleasePoolPage：

			ARC下，我们使用@autoreleasepool{}来使用一个AutoreleasePool，随后编译器将其改写成下面的样子：

			void *context = objc_autoreleasePoolPush();
			// {}中的代码
			objc_autoreleasePoolPop(context);

			AutoreleasePoolPage 是个c++类，上述两个函数只是对这个类的一个简单封装;AutoreleasePoolPage 结构如下：

				magic_t const magic;
				id *next;
				pthread_t const thread;
				AutoreleasePoolPage *const parent;
				AutoreleasePoolPage *child;
				uint32_t const depth;
				uint32_t hiwat;

				a, AutoreleasePool并没有单独的结构，而是由若干个AutoreleasePoolPage以双向链表的形式组合而成（分别对应结构中的parent指针和child指针）
				
				b, AutoreleasePool是按线程一一对应的（结构中的thread指针指向当前线程）
				
				c, AutoreleasePoolPage每个对象会开辟4096字节内存（也就是虚拟内存一页的大小），除了上面的实例变量所占空间，剩下的空间全部用来储存autorelease对象的地址
				
				d, 上面的id *next指针作为游标指向栈顶最新add进来的autorelease对象的下一个位置
				
				e, 一个AutoreleasePoolPage的空间被占满时，会新建一个AutoreleasePoolPage对象，连接链表，后来的autorelease对象在新的page加入

			参数解释：
				
				magic 用来校验 AutoreleasePoolPage 的结构是否完整
				
				next 指向最新添加的 autoreleased 对象的下一个位置，初始化时指向 begin()
				
				thread 指向当前线程
				
				parent 指向父结点，第一个结点的 parent 值为 nil
				
				child 指向子结点，最后一个结点的 child 值为 nil
				
				depth 代表深度，从 0 开始，往后递增 1
				
				hiwat 代表 high water mark


			释放时刻：每当进行一次objc_autoreleasePoolPush调用时，runtime向当前的AutoreleasePoolPage中add进一个哨兵对象，值为0（也就是个nil）

				objc_autoreleasePoolPush的返回值正是这个哨兵对象的地址，被objc_autoreleasePoolPop(哨兵对象)作为入参，于是：
				
				根据传入的哨兵对象地址找到哨兵对象所处的page
				
				在当前page中，将晚于哨兵对象插入的所有autorelease对象都发送一次- release消息，并向回移动next指针到正确位置
				
				补充2：从最新加入的对象一直向前清理，可以向前跨越若干个page，直到哨兵所在的page

5，AFN为什么添加一条常驻线程？

6，简单叙述下KVC与KVO的实现原理？
	
	KVC实现原理：KVC再某种程度上提供了访问器的替代方案。不过访问器方法是一个很好的东西，以至于只要是有可能，
                
                	KVC也尽量在访问器方法的帮助下工作。为了设置或者返回对象属性，KVC按顺序使用如下技术：
                
                	①检查是否存在-<key>、-is<key>（只针对布尔值有效）或者-get<key>的访问器方法，如果有可能，就是用这些方法返回值；
                
                    		检查是否存在名为-set<key>:的方法，并使用它做设置值。对于-get<key>和-set<key>:方法，将大写Key字符串的第一个字母，并与Cocoa的方法命名保持一致；
                
               	 ②如果上述方法不可用，则检查名为-_<key>、-_is<key>（只针对布尔值有效）、-_get<key>和-_set<key>:方法；
                
               	 ③如果没有找到访问器方法，可以尝试直接访问实例变量。实例变量可以是名为：<key>或_<key>;
                
                	④如果仍为找到，则调用valueForUndefinedKey:和setValue:forUndefinedKey:方法。这些方法的默认实现都是抛出异常，我们可以根据需要重写它们。

             KVO实现原理：当某个类的对象第一次被观察时，系统就会在运行期动态地创建该类的一个派生类，在这个派生类中重写基类中任何被观察属性的 setter 方法。派生类在被重写的 setter 方法实现真正的通知机制

        		如果之前的类名为：Person，那么被runtime更改以后的类名会变成：NSKVONotifying_Person。新的NSKVONotifying_Person类会重写以下方法：增加了监听的属性对应的set方法，class，dealloc，_isKVOA

           		①class
            
                		重写class方法是为了我们调用它的时候返回跟重写继承类之前同样的内容
            
            	②重写set方法新类会重写对应的set方法，是为了在set方法中增加另外两个方法的调用：- (void)willChangeValueForKey:(NSString *)key 或者 - (void)didChangeValueForKey:(NSString *)key,  

            		其中，didChangeValueForKey:方法负责调用：- (void)observeValueForKeyPath: ofObject: change: context:这就是KVO实现的原理了！

7，什么是进程？什么是线程？
	
	进程：进程是计算机操作系统分配资源的单位，是指系统中正在运行的一个应用程序，每个进程之间是独立的，每个进程均运行在其专受保护的内存空间内。

	线程：线程是进程的基本执行单元，一个进程的所有任务都在线程中执行。1个进程要执行任务，必须得有线程（每个进程至少要有一个线程）

8,GCD与NSOperation的区别，谁是最早推出的？
	
	GCD先推出的；

	GCD以 block 为单位，代码简洁。同时 GCD 中的队列、组、信号量、source、barriers 都是组成并行编程的基本原语。对于一次性的计算，或是仅仅为了加快现有方法的运行速度，选择轻量化的 GCD 就更加方便。

	NSOperation 可以用来规划一组任务之间的依赖关系，设置它们的优先级，任务能被取消。队列可以暂停、恢复。NSOperation 还可以被子类化。这些都是 GCD 所不具备的。

9,atomic是绝对安全的吗？
	
	atomic的操作是原子性的，但是并不意味着它是线程安全的，它会增加正确的几率，能够更好的避免线程的错误，但是它仍然是线程不安全的
	
	当使用nonatomic的时候，属性的setter，getter操作是非原子性的，所以当多个线程同时对某一属性读和写操作时，属性的最终结果是不能预测的。
	
	当使用atomic时，虽然对属性的读和写是原子性的，但是仍然可能出现线程错误：当线程A进行写操作，这时其他线程的读或者写操作会因为该操作而等待。

	当A线程的写操作结束后，B线程进行写操作，然后当A线程需要读操作时，却获得了在B线程中的值，这就破坏了线程安全，如果有线程C在A线程读操作前release了该属性，

		那么还会导致程序崩溃。所以仅仅使用atomic并不会使得线程安全，我们还要为线程添加lock来确保线程的安全。
	
	也就是要注意：atomic所说的线程安全只是保证了getter和setter存取方法的线程安全，并不能保证整个对象是线程安全的。如下列所示：
	
	比如：@property(atomic,strong)NSMutableArray *arr;  
	
	如果一个线程循环的读数据，一个线程循环写数据，那么肯定会产生内存问题，因为这和setter、getter没有关系。如使用[self.arr objectAtIndex:index]就不是线程安全的。好的解决方案就是加锁。
	     
	     据说，atomic要比nonatomic慢大约20倍。一般如果条件允许，我们可以让服务器来进行加锁操作。

10, 系统是怎样保证父类的类方法，在子类被调用？
	
	当子类调用类方法的时候，系统会在子类的元类中去搜查这个方法，元类保存了类方法的列表。

	当一个类方法被调用时，元类会首先查找它本身是否有该类方法的实现，如果没有，则该元类会向它的父类查找该方法，直到一直找到继承链的头。

	由于类方法的定义是保存在元类 （metaclass） 中，而方法调用的规则是，如果该类没有一个方法的实现，则向它的父类继续查找。

		所以，为了保证父类的类方法可以在子类中可以被调用，所以子类的元类会继承父类的元类，换而言之，类对象和元类对象有着同样的继承关系。

11，一个对象的关联对象又是存在什么地方呢？如何存储？对象销毁时候如何处理关联对象呢？（附加）
	
	所有的关联对象都由AssociationsManager管理AssociationsManager里面是由一个静态AssociationsHashMap来存储所有的关联对象的。

	这相当于把所有对象的关联对象都存在一个全局映射里面。而绘制的的关键是这个对象的指针地址（任意两个不同对象的指针地址一定是不同的），

	而这个地址的值又是另外一个AssociationsHashMap，里面保存了关联对象的KV对。而在对象的销毁逻辑里面，会判断这个对象有没有关联对象，

	如果有，会调用_object_remove_assocations做关联对象的清理工作。

12, 分类的实现原理，分类为什么会覆盖原类的方法？

	类别的实现：

		所有的OC类和对象，在运行时层都是用结构表示的，类别也不例外，在运行时层，类别用结构体category_t（在objc-运行时new.h中可以找到此定义），它包含了一下内容：

			1），类的名字（名）
			2），类（cls）
			3），类中所有给类添加的实例方法的列表（instanceMethods）
			4），类中所有添加的类方法的列表（classMethods ）
			5），类实现的所有协议的列表（协议）
			6），类中添加的所有属性（instanceProperties）(不是实例变量，是属性)

		typedef struct category_t {
		    const char *name;
		    classref_t cls;
		    struct method_list_t *instanceMethods;
		    struct method_list_t *classMethods;
		    struct protocol_list_t *protocols;
		    struct property_list_t *instanceProperties;
		} category_t;

	说明：MyClass 是原类， MyAddition 是MyClass的一个类别

		编译器编译类别时首先会生成一个实例方法列表和属性方法列表，两者的命名都遵循了公共前缀+类名+类别名字的命名方式

		其次，编译器生成了类别本身OBJC $ _CATEGORY MyClass $ _MyAddition，并用前面生成的列表来初始化类本身

		最后，编译器在DATA段下的 objc_catlist部分里保存了一个大小为1的category_t的数组L_OBJC_LABEL CATEGORY $（当然，如果有多 类别，会生成对应长度的数组^ _ ^），用于运行期类的加载。

	类别被附加到类上面是在map_images的时候发生的，在新ABI的标准下，_objc_init里面的调用的map_images最终会调用objc-runtime-new.mm里面的_read_images方法：

		该方法有两个作用：一是把类别的实例方法、协议以及属性添加到类上；二是把类别的类方法和协议添加到类的元类上

		类别各种列表是怎么最终添加到类上的？(以实例方法为例) _read_images方法中，addUnattachedCategoryForClass只是把类和类别做一个关联映射，remethodizeClass这个方法才是把类别的实例方法

			添加到类本身上的功臣，remethodizeClass方法中会调用这个方法attachCategoryMethods，attachCategoryMethods方法的目的就是是把所有类别的实例方法列表拼成了一个大的实例方法列表，

			然后转交给了attachMethodLists方法；attachMethodLists方法会检测类别中的方法是否有覆盖原类中的方法，如果有，就将类别中的方法插入到原类方法列表的中且位置是在原方法的前面；所以

			该方法的注意点：

				1），类的方法没有“完全替换掉”原来类已经有的方法，也就是说如果类别和原来类都有方法A，那类附加完成之后，类的方法列表里会有两个方法A 
				
				2），类的方法被放到了新方法列表的前面，而原来类的方法被放到了新方法列表的后面，这也就是我们平常所说的类方法会“覆盖”掉原来类的同名方法，

				这是因为运行时在查找方法的时候是顺着方法列表的顺序查找的，它只要一找到对应名字的方法，就会罢休^ _ ^，殊不知后面可能还有一样名字的方法

13，一个分类覆盖了原类中的方法，怎么可以在使用该方法时，使得调用的是原类中的方法，而不是分类中？

	类别其实并不是完全替换掉原来类的同名方法，只是类别在方法列表的前面而已，所以我们只要顺着方法列表找到最后一个对应名字的方法，就可以调用原来类的方法：

		Class currentClass = [MyClass class];
		
		MyClass *my = [[MyClass alloc] init];

		if (currentClass) {
		
		    unsigned int methodCount;
		
		    Method *methodList = class_copyMethodList(currentClass, &methodCount);
		
		    IMP lastImp = NULL;
		
		    SEL lastSel = NULL;
		
		    for (NSInteger i = 0; i < methodCount; i++) {
		
		        Method method = methodList[i];
		
		        NSString *methodName = [NSString stringWithCString:sel_getName(method_getName(method)) 
		
		                                        encoding:NSUTF8StringEncoding];
		
		        if ([@"printName" isEqualToString:methodName]) {
		
		            lastImp = method_getImplementation(method);
		
		            lastSel = method_getName(method);
		        }
		    }
		
		    typedef void (*fn)(id,SEL);

		    if (lastImp != NULL) {
		
		        fn f = (fn)lastImp;
		
		        f(my,lastSel);
		    }
		
		    free(methodList);
		}

14，对 id 的理解，以及他的底层原理
	
	id 类型的变量可以存放任何数据类型的对象；在内部处理上，这种类型被定义为指向对象的指针，实际上是一个指向这种对象的实例变量的指针

		id在objc.h中的定义：

			typedef struct objc_object {  
		
			Class isa;  
		
			} *id; 
		id 是指向struct objc_object 的一个指针。也就是说，id 是一个指向任何一个继承了Object（或者NSObject）类的对象。

		需要注意的是id 是一个指针，所以在使用id的时候不需要加星号

15，什么是链表，链表逆序怎么实现

	链表是一种物理存储单元上非连续、非顺序的存储结构，数据元素的逻辑顺序是通过链表中的指针链接次序实现的。链表由一系列结点（链表中每一个元素称为结点）组成
	
	结点可以在运行时动态生成。每个结点包括两个部分：一个是存储数据元素的数据域，另一个是存储下一个结点地址的指针域

16，NSURLSession 相比 NSURLConnection 有哪些优点？
	
	a, 后台上传和下载：只需在创建 NSURLSession 的时候配置一个选项，就能得到后台网络的所有好处。这样可以延长电池寿命，并且还支持 UIKit 的多 task，在进程间使用相同的委托模型

	b, 能够暂停和恢复网络操作：使用 NSURLSession API 能够暂停，停止，恢复所有的网络任务，再也完全不需要子类化 NSOperation

	c, 可配置的容器：对于 NSURLSession 里面的 requests 来说，每个NSURLSession 都是可配置的容器。举个例来说，假如你需要设置 HTTP header 选项，你只用做一次，session 里面的每个 request 就会有同样的配置

	d, 提高认证处理：认证是在一个指定的连接基础上完成的。在使用 NSURLConnection 时，如果发出一个访问，会返回一个任意的 request。此时，你就不能确切的知道哪个 request 收到了访问。而在 NSURLSession 中，就能用代理处理认证

	e, 丰富的代理模式：在处理认证的时候，NSURLConnection 有一些基于异步的 block 方法，但是它的代理方法就不能处理认证，不管请求是成功或是失败。在 NSURLSession 中，可以混合使用代理和 block 方法处理认证

	f, 上传和下载通过文件系统：它鼓励将数据（文件内容）从元数据（URL 和 settings）中分离出来

	