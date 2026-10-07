// Setup.cs — однофайловый установщик SmartPSS. Внутри exe лежат install.ps1 и дистрибутив Dahua:
// он распаковывает их во временную папку и запускает install.ps1 без окна консоли. Требует прав
// администратора (манифест), поэтому окно UAC появляется один раз — при запуске установщика.
// Сборка — build.ps1. Один исходник, два файла:
//   SmartPSS-Setup.exe         мастер «Далее → Установить → Готово»
//   SmartPSS-Setup-Silent.exe  без окон (то же даёт ключ /silent у первого)
using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

[assembly: AssemblyTitle("SmartPSS Setup")]
[assembly: AssemblyProduct("SmartPSS Kit")]
[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.0.0.0")]

public static class Setup
{
    public const string Title = "SmartPSS";
    public static bool Ru = System.Globalization.CultureInfo.CurrentUICulture.TwoLetterISOLanguageName == "ru";
    public static string T(string ru, string en) { return Ru ? ru : en; }

    [DllImport("user32.dll")] static extern bool SetProcessDPIAware();

    public static string Dir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), "SmartPSS-Setup-tmp");

    [STAThread]
    static int Main(string[] args)
    {
        bool silent = Path.GetFileNameWithoutExtension(Application.ExecutablePath).IndexOf("silent", StringComparison.OrdinalIgnoreCase) >= 0;
        foreach (string a in args)
        {
            string s = a.TrimStart('/', '-').ToLowerInvariant();
            if (s == "silent" || s == "verysilent" || s == "quiet" || s == "s" || s == "q") silent = true;
        }
        if (silent)
        {
            try { string o, e; return RunInstall("-Silent", out o, out e); } catch { return 1; }
        }
        SetProcessDPIAware();
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Wizard w = new Wizard();
        Application.Run(w);
        return w.ExitCode;
    }

    // распаковать вложенные файлы в рабочую папку и выполнить install.ps1; вернуть его код выхода
    public static int RunInstall(string psArgs, out string stdout, out string stderr)
    {
        string dir = Dir;
        Directory.CreateDirectory(dir);
        Assembly asm = Assembly.GetExecutingAssembly();
        foreach (string name in asm.GetManifestResourceNames())
        {
            using (Stream src = asm.GetManifestResourceStream(name))
            using (FileStream dst = File.Create(Path.Combine(dir, name)))
                src.CopyTo(dst);
        }
        string ps = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Windows), @"System32\WindowsPowerShell\v1.0\powershell.exe");
        string argLine = "-NoProfile -ExecutionPolicy Bypass -File \"" + Path.Combine(dir, "install.ps1") + "\" -NoFinishBox -Dir \"" + dir + "\" " + psArgs;
        ProcessStartInfo psi = new ProcessStartInfo(ps, argLine);
        psi.UseShellExecute = false;
        psi.CreateNoWindow = true;
        psi.RedirectStandardOutput = true;
        psi.RedirectStandardError = true;
        psi.StandardOutputEncoding = Encoding.UTF8;
        psi.StandardErrorEncoding = Encoding.UTF8;
        using (Process p = Process.Start(psi))
        {
            stdout = p.StandardOutput.ReadToEnd();
            stderr = p.StandardError.ReadToEnd();
            p.WaitForExit();
            try { File.Delete(Path.Combine(dir, "install.ps1")); } catch { }
            try { if (Directory.GetFileSystemEntries(dir).Length == 0) Directory.Delete(dir); } catch { }
            return p.ExitCode;
        }
    }
}

// Мастер: 0 приветствие → 1 параметры → 2 установка → 3 готово
public class Wizard : Form
{
    public int ExitCode = 1;
    int page;
    string error;
    Label head, sub, body;
    ProgressBar bar;
    Button back, next, cancel;
    static string T(string ru, string en) { return Setup.T(ru, en); }
    float scale = 1F;
    int S(int v) { return (int)Math.Round(v * scale); }
    Point P(int x, int y) { return new Point(S(x), S(y)); }
    Size Z(int w, int h) { return new Size(S(w), S(h)); }

    public Wizard()
    {
        SuspendLayout();
        AutoScaleMode = AutoScaleMode.None;
        using (Graphics g = Graphics.FromHwnd(IntPtr.Zero)) scale = g.DpiX / 96F;
        ClientSize = Z(500, 344);
        Text = T("Установка ", "Setup — ") + Setup.Title;
        Font = new Font("Segoe UI", 9F);
        FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = false; MinimizeBox = false;
        StartPosition = FormStartPosition.CenterScreen;

        Panel header = new Panel(); header.BackColor = Color.White; header.Location = P(0, 0); header.Size = Z(500, 66);
        head = new Label(); head.Font = new Font("Segoe UI", 11F, FontStyle.Bold); head.Location = P(18, 12); head.Size = Z(464, 24);
        sub = new Label(); sub.ForeColor = Color.FromArgb(90, 90, 90); sub.Location = P(18, 38); sub.Size = Z(464, 20);
        header.Controls.Add(head); header.Controls.Add(sub);
        Label line1 = new Label(); line1.BorderStyle = BorderStyle.Fixed3D; line1.Location = P(0, 66); line1.Size = Z(500, 2);

        body = new Label(); body.Location = P(24, 86); body.Size = Z(452, 196);
        bar = new ProgressBar(); bar.Style = ProgressBarStyle.Marquee; bar.MarqueeAnimationSpeed = 30; bar.Location = P(24, 150); bar.Size = Z(452, 18); bar.Visible = false;

        Label line2 = new Label(); line2.BorderStyle = BorderStyle.Fixed3D; line2.Location = P(0, 292); line2.Size = Z(500, 2);
        back = new Button(); back.Text = T("< Назад", "< Back"); back.Location = P(206, 306); back.Size = Z(88, 26);
        next = new Button(); next.Location = P(300, 306); next.Size = Z(88, 26);
        cancel = new Button(); cancel.Text = T("Отмена", "Cancel"); cancel.Location = P(400, 306); cancel.Size = Z(88, 26);
        back.Click += delegate { ShowPage(0); };
        next.Click += delegate { if (page == 0) StartInstall(); else Close(); };
        cancel.Click += delegate { Close(); };
        AcceptButton = next; CancelButton = cancel;

        Controls.Add(bar); Controls.Add(body);
        Controls.Add(header); Controls.Add(line1); Controls.Add(line2);
        Controls.Add(back); Controls.Add(next); Controls.Add(cancel);
        ResumeLayout(false);
        PerformLayout();

        FormClosing += delegate(object s, FormClosingEventArgs e) { if (page == 2) e.Cancel = true; };
        ShowPage(0);
    }

    public void ShowPage(int p)
    {
        page = p;
        body.Visible = (p != 2);
        bar.Visible = (p == 2);
        back.Visible = (p == 0 && false);
        next.Enabled = (p != 2);
        cancel.Enabled = (p < 2);
        switch (p)
        {
            case 0:
                head.Text = T("Установка ", "Welcome to ") + Setup.Title + T("", " Setup");
                sub.Text = T("Видеонаблюдение Dahua — запуск без запроса UAC", "Dahua surveillance client — launch without a UAC prompt");
                body.Text = T("Установщик поставит SmartPSS (если он ещё не установлен) и настроит запуск программы "
                            + "с правами администратора без окна UAC при каждом старте.\n\n"
                            + "Во время установки может открыться мастер SmartPSS от Dahua — пройдите его до конца.\n\n"
                            + "Нажмите «Установить», чтобы продолжить.",
                              "Setup will install SmartPSS (if it is not already installed) and configure it to run elevated "
                            + "without a UAC prompt on every launch.\n\n"
                            + "The Dahua SmartPSS wizard may open during installation - just complete it.\n\n"
                            + "Click Install to continue.");
                next.Text = T("Установить", "Install");
                break;
            case 2:
                head.Text = T("Установка", "Installing");
                sub.Text = T("Подождите, это может занять минуту", "Please wait, this may take a minute");
                body.Text = T("Распаковка и настройка…", "Extracting and setting up…");
                break;
            case 3:
                head.Text = T("Установка завершена", "Installation complete");
                sub.Text = Setup.Title + T(" установлен", " is installed");
                body.Text = T("Запускайте SmartPSS ярлыком на рабочем столе или в меню «Пуск» — окна UAC больше не будет.\n\n"
                            + "Ярлыки уже настроены на запуск с правами администратора через Планировщик заданий.",
                              "Launch SmartPSS from the Desktop or Start Menu shortcut - there will be no UAC prompt.\n\n"
                            + "The shortcuts are set to run elevated via Task Scheduler.");
                next.Text = T("Готово", "Finish");
                next.Focus();
                break;
        }
    }

    void StartInstall()
    {
        ShowPage(2);
        Task.Factory.StartNew<int>(delegate
        {
            try { string o, e; int c = Setup.RunInstall("", out o, out e); if (c != 0 && string.IsNullOrEmpty(error)) error = (e + "\n" + o).Trim(); return c; }
            catch (Exception ex) { error = ex.Message; return 1; }
        }).ContinueWith(delegate(Task<int> t) { Done(t.Result); }, TaskScheduler.FromCurrentSynchronizationContext());
    }

    void Done(int code)
    {
        ExitCode = code;
        page = 3;
        if (code != 0)
        {
            MessageBox.Show(this, T("Установка не удалась:\n\n", "Installation failed:\n\n") + (error ?? ""), Setup.Title, MessageBoxButtons.OK, MessageBoxIcon.Error);
            Close();
            return;
        }
        ShowPage(3);
        Activate();
    }
}
