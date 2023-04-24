defmodule MagWeb.HomeController do
  use MagWeb, :controller

  defp posts() do
    List.duplicate(%{
      title: "Arrested Khalistan symapthiser Amripal Singh likely tobe shifted to Assam",
      content: """
      MOGA (Punjab): Khalistan sympathiser and radical preacher Amritpal Singh who was absconding for over a month is likely to be shifted to Dibrugarh, Assam, informed Punjab Police sources.

      'Waris Punjab De' chief Amritpal Singh was arrested by Punjab Police from the Moga district of Punjab.

      Amritpal has been on the run since March 18, the day Punjab Police launched a massive manhunt for him.

      Papalpreet Singh, a close aide of Amritpal Singh, was taken to Assam's Dibrugarh Central Jail on April 11 after he was arrested.

      Associates of Amritpal Singh were shifted out of Punjab after Central Intelligence agencies raised concerns over possible jailbreak and repeat of the Ajnala incident on March 11.

      Earlier on Saturday, Union Home Minister Amit Shah when asked about Amritpal Singh's arrest and that he has been absconding for a long, said, "It may happen sometime. Earlier he used to roam freely, but now he cannot carry on with his activities."

      Two more aides of 'Waris Punjab De' chief Amritpal Singh were arrested at Mohali in Punjab, in a joint operation by Punjab and Delhi Police on April 18.

      On April 15, Punjab Police arrested his close aide Joga Singh from Sirhind in the Fatehgarh Sahib district.

      The radical leader had been declared a "fugitive" while he was on a run earlier in March.

      "Waris Punjab De' chief Amritpal Singh has been declared a fugitive. His two cars were seized and gunmen nabbed. We also checked if the firearms of his security escorts had been procured legally. A case has been registered. Punjab Police have launched a manhunt for Amritpal Singh and we are hopeful that he will be arrested soon. A total of 78 people have been arrested so far and further searches and raids are underway," Chahal said in an exclusive interview with ANI.

      The crackdown came almost over three weeks after Amritpal's supporters stormed Ajnala police station in Amritsar on February 23, demanding the release of one of his aides, Lovepreet Toofan.

      Related video: Amritpal Singh | Amritpal Singh Arrested | Amritpal Singh To Be Taken To Assam | Amritpal Singh News (News18)
      """
    }, 50)
    |> List.insert_at(0, %{title: "test", content: "test"})
  end


  def home(conn, _params) do
    render(conn, :home, posts: posts)
  end
end
